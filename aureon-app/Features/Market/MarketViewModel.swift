//
//  MarketViewModel.swift
//  aureon-app
//
//  市场域视图模型：自选、实时行情（SSE + 轮询降级）、K 线、指标、回放、AI 摘要。
//  对齐 Web 版 DashboardClient.tsx / OhlcvDesk.tsx 的核心工作流。
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class MarketViewModel {
    private let repository: DataRepository
    private let haptics: HapticsManager

    var instId: String
    var interval: CandleInterval = .fifteenMinutes
    var watchlist: LoadState<[WatchlistItem]> = .idle
    var ticker: TickerSnapshot?
    var candles: LoadState<[Candle]> = .idle
    var liveness: ConnectionLiveness = .polling
    var indicatorsEnabled = IndicatorToggles()
    var selectedCandle: Candle?
    var isReplaying = false
    var replayIndex: Int = 0
    var aiSummary: LoadState<String> = .idle
    var isPlacingOrder = false
    var orderErrorMessage: String?
    var lastOrderConfirmation: OrderRecord?

    private var streamTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?

    init(instId: String, repository: DataRepository, haptics: HapticsManager) {
        self.instId = instId
        self.repository = repository
        self.haptics = haptics
    }

    var visibleCandles: [Candle] {
        guard let all = candles.value else { return [] }
        guard isReplaying else { return all }
        return Array(all.prefix(max(replayIndex, 2)))
    }

    var emaFast: [Double] { movingAverage(period: 7) }
    var emaSlow: [Double] { movingAverage(period: 25) }
    var rsi: [Double] { relativeStrengthIndex(period: 14) }

    func loadAll() async {
        async let watchlistResult: Void = loadWatchlist()
        async let candlesResult: Void = loadCandles()
        async let tickerResult: Void = loadTickerOnce()
        _ = await (watchlistResult, candlesResult, tickerResult)
        startStream()
    }

    func changeInstrument(to newInstId: String) async {
        guard newInstId != instId else { return }
        stopStream()
        instId = newInstId
        candles = .loading
        aiSummary = .idle
        selectedCandle = nil
        isReplaying = false
        await loadCandles()
        await loadTickerOnce()
        startStream()
    }

    func changeInterval(to newInterval: CandleInterval) async {
        guard newInterval != interval else { return }
        interval = newInterval
        await loadCandles()
    }

    func loadWatchlist() async {
        watchlist = .loading
        do {
            let items = try await repository.fetchWatchlist()
            watchlist = items.isEmpty ? .empty : .loaded(items)
            syncWatchlistWidgetSnapshot(items)
        } catch {
            watchlist = .failed(error.localizedDescription)
        }
    }

    private func syncWatchlistWidgetSnapshot(_ items: [WatchlistItem]) {
        let snapshots = items.map { item -> WatchlistWidgetSnapshot in
            let ticker = MockMarketFactory.ticker(instId: item.instId)
            return WatchlistWidgetSnapshot(instId: item.instId, last: ticker.last, changePercent24h: ticker.changePercent24h)
        }
        WidgetSnapshotStore.updateWatchlist(snapshots)
    }

    func toggleWatchlist() async {
        let isWatched = watchlist.value?.contains { $0.instId == instId } ?? false
        do {
            let items = try await repository.toggleWatchlist(instId: instId, add: !isWatched)
            watchlist = items.isEmpty ? .empty : .loaded(items)
            haptics.impact(.light)
        } catch {
            watchlist = .failed(error.localizedDescription)
        }
    }

    func loadCandles() async {
        candles = .loading
        do {
            let result = try await repository.fetchCandles(instId: instId, bar: interval, limit: 180)
            candles = result.isEmpty ? .empty : .loaded(result)
            replayIndex = result.count
        } catch {
            candles = .failed(error.localizedDescription)
        }
    }

    private func loadTickerOnce() async {
        do {
            ticker = try await repository.fetchTicker(instId: instId)
        } catch {
            // 静默失败：ticker 头部会保留最近一次值，SSE/轮询会继续尝试恢复。
        }
    }

    func startStream() {
        stopStream()
        let capturedInstId = instId
        streamTask = Task { [repository] in
            var didReceiveAnyTick = false
            for await event in await repository.streamTicker(instId: capturedInstId) {
                if Task.isCancelled { break }
                switch event {
                case .connected:
                    liveness = .live
                case .tick(let snapshot):
                    didReceiveAnyTick = true
                    liveness = .live
                    ticker = snapshot
                case .error:
                    liveness = .polling
                case .disconnected:
                    liveness = didReceiveAnyTick ? .polling : .offline
                }
            }
            if !Task.isCancelled, liveness != .live {
                startPollingFallback()
            }
        }
    }

    private func startPollingFallback() {
        pollTask?.cancel()
        pollTask = Task { [repository] in
            while !Task.isCancelled {
                if let latest = try? await repository.fetchTicker(instId: self.instId) {
                    self.ticker = latest
                }
                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
    }

    func stopStream() {
        streamTask?.cancel()
        streamTask = nil
        pollTask?.cancel()
        pollTask = nil
    }

    func requestAISummary() async {
        aiSummary = .loading
        do {
            let summary = try await repository.analyzeCandles(instId: instId, bar: interval)
            aiSummary = .loaded(summary)
        } catch {
            aiSummary = .failed(error.localizedDescription)
        }
    }

    func toggleReplay() {
        isReplaying.toggle()
        if isReplaying, let all = candles.value {
            replayIndex = max(2, all.count / 3)
        }
    }

    func stepReplay(by delta: Int) {
        guard let all = candles.value else { return }
        replayIndex = min(max(replayIndex + delta, 2), all.count)
    }

    func placeSimulatedOrder(side: OrderSide, sizeUsd: Double, instType: InstrumentType, leverage: Double) async {
        isPlacingOrder = true
        orderErrorMessage = nil
        defer { isPlacingOrder = false }
        do {
            let order = try await repository.placeOrder(instId: instId, instType: instType, side: side, sizeUsd: sizeUsd, leverage: leverage)
            lastOrderConfirmation = order
            haptics.success()
        } catch let envelope as APIErrorEnvelope {
            orderErrorMessage = envelope.message
            haptics.error()
        } catch {
            orderErrorMessage = error.localizedDescription
            haptics.error()
        }
    }

    // MARK: - 指标计算（本地实现，等价于 Web 版 EMA/RSI 叠加层）

    private func movingAverage(period: Int) -> [Double] {
        let closes = visibleCandles.map(\.close)
        guard closes.count >= period, period > 0 else { return [] }
        let multiplier = 2.0 / Double(period + 1)
        var result: [Double] = []
        var ema = closes.prefix(period).reduce(0, +) / Double(period)
        result.append(ema)
        for close in closes.dropFirst(period) {
            ema = (close - ema) * multiplier + ema
            result.append(ema)
        }
        return result
    }

    private func relativeStrengthIndex(period: Int) -> [Double] {
        let closes = visibleCandles.map(\.close)
        guard closes.count > period else { return [] }
        var gains = 0.0
        var losses = 0.0
        for index in 1...period {
            let delta = closes[index] - closes[index - 1]
            if delta >= 0 { gains += delta } else { losses -= delta }
        }
        var avgGain = gains / Double(period)
        var avgLoss = losses / Double(period)
        var result: [Double] = [avgLoss == 0 ? 100 : 100 - (100 / (1 + avgGain / avgLoss))]

        for index in (period + 1)..<closes.count {
            let delta = closes[index] - closes[index - 1]
            let gain = max(delta, 0)
            let loss = max(-delta, 0)
            avgGain = (avgGain * Double(period - 1) + gain) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + loss) / Double(period)
            let rs = avgLoss == 0 ? Double.infinity : avgGain / avgLoss
            result.append(avgLoss == 0 ? 100 : 100 - (100 / (1 + rs)))
        }
        return result
    }
}

struct IndicatorToggles: Equatable {
    var showEmaFast = true
    var showEmaSlow = true
    var showRsi = false
    var showVolume = true
}
