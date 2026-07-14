//
//  StrategyViewModel.swift
//  aureon-app
//
//  策略域视图模型：模板 CRUD、回测/Walk-forward/参数扫描、运行列表与本地纸面运行。
//  对齐 Web 版 StrategyConsole.tsx / BacktestPanel.tsx / RunList.tsx。
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class StrategyViewModel {
    private let repository: DataRepository
    private let notifications: NotificationManager
    private let haptics: HapticsManager
    private let liveActivity: LiveActivityManager?

    var presets: LoadState<[StrategyPreset]> = .idle
    var templates: LoadState<[StrategyTemplate]> = .idle
    var runs: LoadState<[TemplateRun]> = .idle

    var draft = StrategyTemplateDraft()
    var isEditingTemplateId: String?

    var backtestResult: LoadState<BacktestResult> = .idle
    var walkForwardResult: LoadState<WalkForwardResult> = .idle
    var paramScanResult: LoadState<ParamScanResult> = .idle

    var paperRun = PaperRunState()
    private var paperTask: Task<Void, Never>?

    var selectedRunId: String?
    var runOrders: LoadState<[TemplateOrderRow]> = .idle
    var runTicks: LoadState<[TemplateRunTick]> = .idle

    init(repository: DataRepository, notifications: NotificationManager, haptics: HapticsManager, liveActivity: LiveActivityManager? = nil) {
        self.repository = repository
        self.notifications = notifications
        self.haptics = haptics
        self.liveActivity = liveActivity
    }

    func loadAll() async {
        async let presetsResult: Void = loadPresets()
        async let templatesResult: Void = loadTemplates()
        async let runsResult: Void = loadRuns()
        _ = await (presetsResult, templatesResult, runsResult)
    }

    func loadPresets() async {
        presets = .loading
        do {
            let result = try await repository.fetchStrategyPresets()
            presets = result.isEmpty ? .empty : .loaded(result)
        } catch {
            presets = .failed(error.localizedDescription)
        }
    }

    func loadTemplates() async {
        templates = .loading
        do {
            let result = try await repository.fetchTemplates()
            templates = result.isEmpty ? .empty : .loaded(result)
        } catch {
            templates = .failed(error.localizedDescription)
        }
    }

    func loadRuns() async {
        runs = .loading
        do {
            let result = try await repository.fetchRuns()
            runs = result.isEmpty ? .empty : .loaded(result)
            syncWidgetSnapshot(result)
        } catch {
            runs = .failed(error.localizedDescription)
        }
    }

    private func syncWidgetSnapshot(_ runs: [TemplateRun]) {
        let runningRuns = runs.filter { $0.status == .running }
        guard let top = runningRuns.max(by: { $0.realizedPnlUsd < $1.realizedPnlUsd }) else {
            return
        }
        WidgetSnapshotStore.updateStrategySummary(StrategyWidgetSnapshot(
            runningCount: runningRuns.count,
            topTemplateName: top.templateName,
            topRealizedPnlUsd: top.realizedPnlUsd,
            updatedAt: .now
        ))
    }

    func beginNewDraft(style: StrategyStyle) {
        draft = StrategyTemplateDraft(style: style)
        isEditingTemplateId = nil
    }

    func editTemplate(_ template: StrategyTemplate) {
        draft = StrategyTemplateDraft(template: template)
        isEditingTemplateId = template.id
    }

    func saveDraft() async {
        let template = draft.toTemplate(existingId: isEditingTemplateId)
        do {
            if isEditingTemplateId != nil {
                _ = try await repository.updateTemplate(template)
            } else {
                _ = try await repository.createTemplate(template)
            }
            haptics.success()
            await loadTemplates()
        } catch {
            haptics.error()
        }
    }

    func deleteTemplate(id: String) async {
        try? await repository.deleteTemplate(id: id)
        await loadTemplates()
    }

    func startRun(templateId: String) async {
        guard let run = try? await repository.startRun(templateId: templateId) else { return }
        notifications.notifyStrategyStatus(templateName: run.templateName, status: .running)
        haptics.impact(.medium)
        liveActivity?.startOrUpdateStrategyRun(runId: run.id, templateName: run.templateName, style: run.style, statusLabelZh: run.status.labelZh, progressPercent: 0, realizedPnlUsd: run.realizedPnlUsd)
        await loadRuns()
    }

    func setRunStatus(runId: String, status: RunStatus) async {
        guard let run = try? await repository.setRunStatus(runId: runId, status: status) else { return }
        notifications.notifyStrategyStatus(templateName: run.templateName, status: status)
        if status == .stopped || status == .completed {
            liveActivity?.endActivity(runId: runId)
        } else {
            liveActivity?.startOrUpdateStrategyRun(runId: run.id, templateName: run.templateName, style: run.style, statusLabelZh: run.status.labelZh, progressPercent: status == .running ? 50 : 0, realizedPnlUsd: run.realizedPnlUsd)
        }
        await loadRuns()
    }

    func openRunDetail(runId: String) async {
        selectedRunId = runId
        runOrders = .loading
        runTicks = .loading
        do {
            let orders = try await repository.fetchRunOrders(runId: runId)
            runOrders = orders.isEmpty ? .empty : .loaded(orders)
        } catch {
            runOrders = .failed(error.localizedDescription)
        }
        do {
            let ticks = try await repository.fetchRunTicks(runId: runId)
            runTicks = ticks.isEmpty ? .empty : .loaded(ticks)
        } catch {
            runTicks = .failed(error.localizedDescription)
        }
    }

    // MARK: - 回测

    func runBacktest() async {
        backtestResult = .loading
        do {
            let request = draft.toBacktestRequest()
            let result = try await repository.runBacktest(request)
            backtestResult = .loaded(result)
            notifications.notifyBacktestCompleted(templateName: draft.name, totalReturnPercent: result.summary.totalReturnPercent)
        } catch {
            backtestResult = .failed(error.localizedDescription)
        }
    }

    func runWalkForward() async {
        walkForwardResult = .loading
        do {
            let result = try await repository.runWalkForward(draft.toBacktestRequest())
            walkForwardResult = .loaded(result)
        } catch {
            walkForwardResult = .failed(error.localizedDescription)
        }
    }

    func runParamScan() async {
        paramScanResult = .loading
        do {
            let result = try await repository.runParamScan(draft.toBacktestRequest())
            paramScanResult = .loaded(result)
        } catch {
            paramScanResult = .failed(error.localizedDescription)
        }
    }

    // MARK: - 本地纸面运行（浏览器端等价逻辑：仅依赖价格流，session 级、不持久化）

    func startPaperRun() {
        guard paperRun.status != .running else { return }
        paperRun = PaperRunState()
        paperRun.status = .running
        let request = draft.toBacktestRequest()
        paperTask?.cancel()
        paperTask = Task {
            var reference = MockMarketFactory.basePrice(for: request.instId)
            while !Task.isCancelled, self.paperRun.status == .running {
                let tick = MockMarketFactory.ticker(instId: request.instId, referencePrice: reference)
                reference = tick.last
                self.advancePaperRun(price: tick.last, request: request)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func stopPaperRun() {
        paperRun.status = .stopped
        paperTask?.cancel()
        paperTask = nil
    }

    private func advancePaperRun(price: Double, request: BacktestRequest) {
        var generator = SeededGenerator(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        if let position = paperRun.position {
            let pnlPercent = (position.side == .buy ? (price - position.entryPrice) : (position.entryPrice - price)) / position.entryPrice * 100
            if pnlPercent >= request.risk.takeProfitPercent || pnlPercent <= -request.risk.stopLossPercent {
                paperRun.equity *= (1 + pnlPercent / 100 * 0.1)
                paperRun.trades.append(TradeRecord(
                    id: UUID().uuidString, entryAt: position.enteredAt, exitAt: .now,
                    side: position.side, entryPrice: position.entryPrice, exitPrice: price,
                    pnlPercent: pnlPercent, isWin: pnlPercent >= 0
                ))
                paperRun.position = nil
            }
        } else if generator.nextDouble() > 0.6 {
            paperRun.position = PaperPosition(side: generator.nextDouble() > 0.5 ? .buy : .sell, entryPrice: price, size: 1, enteredAt: .now)
        }
        paperRun.equityCurve.append(EquityPoint(t: .now, equity: paperRun.equity))
        if paperRun.equityCurve.count > 120 { paperRun.equityCurve.removeFirst() }
    }
}

/// 策略编辑器草稿，覆盖规则参数、仓位、杠杆、TP/SL 与频率配置。
struct StrategyTemplateDraft: Equatable {
    var name: String = "新策略模板"
    var style: StrategyStyle = .balanced
    var instId: String = "BTC-USDT"
    var instType: InstrumentType = .spot
    var frequencyKind: StrategyFrequencyKind = .interval
    var intervalSeconds: Int = 300
    var sizingUsd: Double = 500
    var leverage: Double = 1
    var takeProfitPercent: Double = 6
    var stopLossPercent: Double = 3
    var maxLeverage: Double = 5
    var bar: CandleInterval = .fifteenMinutes

    init() {}

    init(style: StrategyStyle) {
        self.style = style
        self.name = "\(style.titleZh) 模板"
    }

    init(template: StrategyTemplate) {
        name = template.name
        style = template.style
        instId = template.instId
        instType = template.instType
        frequencyKind = template.frequency.kind
        intervalSeconds = template.frequency.intervalSeconds
        sizingUsd = template.entrySizing.usdAmount
        leverage = template.leverage
        takeProfitPercent = template.risk.takeProfitPercent
        stopLossPercent = template.risk.stopLossPercent
        maxLeverage = template.risk.maxLeverage
    }

    func toTemplate(existingId: String?) -> StrategyTemplate {
        StrategyTemplate(
            id: existingId ?? UUID().uuidString,
            name: name,
            style: style,
            instId: instId,
            instType: instType,
            frequency: StrategyFrequency(kind: frequencyKind, intervalSeconds: intervalSeconds, cronExpression: nil),
            entrySizing: EntrySizing(usdAmount: sizingUsd, percentOfEquity: nil),
            leverage: leverage,
            risk: RiskConfig(takeProfitPercent: takeProfitPercent, stopLossPercent: stopLossPercent, maxLeverage: maxLeverage),
            ruleParams: ["fastMa": 7, "slowMa": 25, "rsiPeriod": 14],
            createdAt: .now,
            updatedAt: .now,
            lastBacktestSummary: nil
        )
    }

    func toBacktestRequest() -> BacktestRequest {
        BacktestRequest(
            instId: instId,
            instType: instType,
            bar: bar,
            limit: 200,
            style: style,
            sizingUsd: sizingUsd,
            leverage: leverage,
            risk: RiskConfig(takeProfitPercent: takeProfitPercent, stopLossPercent: stopLossPercent, maxLeverage: maxLeverage)
        )
    }
}
