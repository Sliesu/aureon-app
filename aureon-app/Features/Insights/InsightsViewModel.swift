//
//  InsightsViewModel.swift
//  aureon-app
//
//  洞察域视图模型：AI/规则建议评估、历史、宏观、新闻、市场情报、订单簿、审计。
//

import Foundation
import Observation

@MainActor
@Observable
final class InsightsViewModel {
    private let repository: DataRepository
    private let haptics: HapticsManager

    var instId: String
    var history: LoadState<[AdviceRecord]> = .idle
    var metrics: AdviceEvaluationMetrics = .placeholder
    var macro: LoadState<MacroSnapshot> = .idle
    var headlines: LoadState<[HeadlineItem]> = .idle
    var marketIntel: LoadState<MarketIntelSnapshot> = .idle
    var orderBook: LoadState<OrderBookSnapshot> = .idle
    var audit: LoadState<[AuditEvent]> = .idle
    var isEvaluating = false

    init(instId: String, repository: DataRepository, haptics: HapticsManager) {
        self.instId = instId
        self.repository = repository
        self.haptics = haptics
    }

    func loadAll() async {
        async let a: Void = loadHistory()
        async let b: Void = loadMacro()
        async let c: Void = loadHeadlines()
        async let d: Void = loadMarketIntel()
        async let e: Void = loadOrderBook()
        async let f: Void = loadAudit()
        metrics = (try? await repository.fetchEvaluationMetrics()) ?? .placeholder
        _ = await (a, b, c, d, e, f)
    }

    func loadHistory() async {
        history = .loading
        do {
            let result = try await repository.fetchAdviceHistory()
            history = result.isEmpty ? .empty : .loaded(result)
        } catch {
            history = .failed(error.localizedDescription)
        }
    }

    func evaluate() async {
        isEvaluating = true
        defer { isEvaluating = false }
        do {
            _ = try await repository.evaluateAdvice(instId: instId)
            haptics.success()
            await loadHistory()
        } catch {
            haptics.error()
        }
    }

    func loadMacro() async {
        macro = .loading
        do { macro = .loaded(try await repository.fetchMacro()) } catch { macro = .failed(error.localizedDescription) }
    }

    func loadHeadlines() async {
        headlines = .loading
        do {
            let result = try await repository.fetchHeadlines()
            headlines = result.isEmpty ? .empty : .loaded(result)
        } catch {
            headlines = .failed(error.localizedDescription)
        }
    }

    func loadMarketIntel() async {
        marketIntel = .loading
        do { marketIntel = .loaded(try await repository.fetchMarketIntel(instId: instId)) } catch { marketIntel = .failed(error.localizedDescription) }
    }

    func loadOrderBook() async {
        orderBook = .loading
        do { orderBook = .loaded(try await repository.fetchOrderBook(instId: instId)) } catch { orderBook = .failed(error.localizedDescription) }
    }

    func loadAudit() async {
        audit = .loading
        do {
            let result = try await repository.fetchAuditEvents()
            audit = result.isEmpty ? .empty : .loaded(result)
        } catch {
            audit = .failed(error.localizedDescription)
        }
    }
}
