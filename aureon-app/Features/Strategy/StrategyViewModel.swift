//
//  StrategyViewModel.swift
//  aureon-app
//
//  策略域视图模型：模板 CRUD、回测/Walk-forward/参数扫描、运行列表与本地纸面运行。
//  对齐 Web 版 StrategyConsole.tsx / BacktestPanel.tsx / RunList.tsx。
//

import AureonShared
import Foundation
import Observation
import UIKit
import WidgetKit

@MainActor
@Observable
final class StrategyViewModel {
    private let repository: DataRepository
    private let notifications: NotificationManager
    private let haptics: HapticsManager
    private let liveActivity: LiveActivityManager?
    private let aiResearchProvider: BacktestAIResearchProviding

    var presets: LoadState<[StrategyPreset]> = .idle
    var templates: LoadState<[StrategyTemplate]> = .idle
    var runs: LoadState<[TemplateRun]> = .idle

    var draft = StrategyTemplateDraft()
    var isEditingTemplateId: String?
    private var draftBaseline = StrategyTemplateDraft()
    var draftSaveError: String?
    var draftSavedAt: Date?
    /// 草稿相对最近一次加载/保存基线是否发生改动，供编辑页展示脏数据提示。
    var isDraftDirty: Bool { draft != draftBaseline }
    /// `TemplatesWorkspaceView` 监听该字段以决定何时把编辑器推入导航栈，
    /// 消费后应重置为 nil，避免重复触发导航。
    enum TemplateNavigationRequest: Equatable { case newDraft, editDraft }
    var pendingTemplateNavigation: TemplateNavigationRequest?

    var backtestResult: LoadState<BacktestResult> = .idle
    var walkForwardResult: LoadState<WalkForwardResult> = .idle
    var paramScanResult: LoadState<ParamScanResult> = .idle
    /// 针对当前 `backtestResult` 的 AI 研判。默认 Provider 为占位实现（见
    /// `BacktestAIResearchProvider.swift`），真实接入 LLM 后端前始终展示「即将上线」。
    var aiResearch: LoadState<BacktestAIResearch> = .idle

    var paperRun = PaperRunState()
    private var paperTask: Task<Void, Never>?

    /// 启动运行失败的原因（如模板已有活跃实例），供总览/模板库展示提示。
    var startRunError: String?
    /// 正在执行生命周期动作（暂停/恢复/归档）的运行 id，用于禁用重复点击。
    var pendingRunActions: Set<String> = []
    /// 按 runId 记录的最近一次生命周期动作失败原因。
    var runActionErrors: [String: String] = [:]

    init(
        repository: DataRepository,
        notifications: NotificationManager,
        haptics: HapticsManager,
        liveActivity: LiveActivityManager? = nil,
        aiResearchProvider: BacktestAIResearchProviding = NoOpBacktestAIResearchProvider()
    ) {
        self.repository = repository
        self.notifications = notifications
        self.haptics = haptics
        self.liveActivity = liveActivity
        self.aiResearchProvider = aiResearchProvider
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
        if let top = runningRuns.max(by: { $0.realizedPnlUsd < $1.realizedPnlUsd }) {
            WidgetSnapshotStore.updateStrategySummary(StrategyWidgetSnapshot(
                runningCount: runningRuns.count,
                topTemplateName: top.templateName,
                topRealizedPnlUsd: top.realizedPnlUsd,
                updatedAt: .now
            ))
        } else {
            // 无运行中策略时清空快照，避免小组件残留已停止策略的旧数据。
            WidgetSnapshotStore.updateStrategySummary(nil)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: AureonWidgetKind.strategy)
    }

    func beginNewDraft(style: StrategyStyle) {
        draft = StrategyTemplateDraft(style: style)
        draftBaseline = draft
        draftSaveError = nil
        draftSavedAt = nil
        isEditingTemplateId = nil
        pendingTemplateNavigation = .newDraft
    }

    func editTemplate(_ template: StrategyTemplate) {
        draft = StrategyTemplateDraft(template: template)
        draftBaseline = draft
        draftSaveError = nil
        draftSavedAt = nil
        isEditingTemplateId = template.id
        pendingTemplateNavigation = .editDraft
    }

    /// 供「策略回测」在不进入编辑页的情况下切换回测对象（不同策略模板）。
    /// 切换后清空旧结果，避免误把上一个策略的回测数据当作新策略的表现。
    func selectTemplateForBacktest(_ template: StrategyTemplate) {
        guard isEditingTemplateId != template.id else { return }
        draft = StrategyTemplateDraft(template: template)
        draftBaseline = draft
        draftSaveError = nil
        draftSavedAt = nil
        isEditingTemplateId = template.id
        backtestResult = .idle
        walkForwardResult = .idle
        paramScanResult = .idle
        aiResearch = .idle
    }

    /// 请求针对当前回测结果的 AI 研判。默认 Provider 会抛出 `.notConfigured`，
    /// 此处统一转换为友好的占位说明，而非把底层网络错误文案直接展示给用户。
    func requestAIResearch() async {
        guard case .loaded(let result) = backtestResult else { return }
        aiResearch = .loading
        do {
            let research = try await aiResearchProvider.generateResearch(for: result)
            aiResearch = .loaded(research)
        } catch {
            aiResearch = .failed("AI 研判功能即将上线，需接入后端 LLM API 后启用。")
        }
    }

    @discardableResult
    func saveDraft() async -> Bool {
        let template = draft.toTemplate(existingId: isEditingTemplateId)
        do {
            if isEditingTemplateId != nil {
                _ = try await repository.updateTemplate(template)
            } else {
                _ = try await repository.createTemplate(template)
                isEditingTemplateId = template.id
            }
            haptics.success()
            draftBaseline = draft
            draftSavedAt = .now
            draftSaveError = nil
            await loadTemplates()
            return true
        } catch {
            haptics.error()
            draftSaveError = Self.message(for: error)
            return false
        }
    }

    func deleteTemplate(id: String) async {
        try? await repository.deleteTemplate(id: id)
        await loadTemplates()
    }

    /// 启动新运行。同一模板存在活跃（运行中/暂停中）实例时，仓库层会拒绝并返回错误，
    /// 此处不再用 `try?` 吞掉失败，而是记录到 `startRunError` 供 UI 展示。
    @discardableResult
    func startRun(templateId: String) async -> Bool {
        startRunError = nil
        do {
            let run = try await repository.startRun(templateId: templateId)
            notifications.notifyStrategyStatus(templateName: run.templateName, status: .running)
            haptics.impact(.medium)
            liveActivity?.startOrUpdateStrategyRun(runId: run.id, templateName: run.templateName, style: run.style, statusLabelZh: run.status.labelZh, progressPercent: 0, realizedPnlUsd: run.realizedPnlUsd)
            await loadRuns()
            return true
        } catch {
            haptics.error()
            startRunError = Self.message(for: error)
            return false
        }
    }

    /// 受约束的生命周期动作入口：仅接受 `RunLifecycleAction`，非法跃迁由仓库层拒绝。
    /// 成功后局部更新 `runs` 列表并同步通知 / Live Activity / Widget，避免整表刷新失败时
    /// 造成多端状态不一致；失败则记录到 `runActionErrors[runId]`，不修改本地状态。
    func performRunAction(runId: String, action: RunLifecycleAction) async {
        guard !pendingRunActions.contains(runId) else { return }
        pendingRunActions.insert(runId)
        runActionErrors[runId] = nil
        defer { pendingRunActions.remove(runId) }
        do {
            let run = try await repository.performRunAction(runId: runId, action: action)
            applyRunLocally(run)
            notifications.notifyStrategyStatus(templateName: run.templateName, status: run.status)
            if run.status.isTerminal {
                liveActivity?.endActivity(runId: runId, finalStatusLabelZh: run.status.labelZh, finalRealizedPnlUsd: run.realizedPnlUsd)
            } else {
                liveActivity?.startOrUpdateStrategyRun(runId: run.id, templateName: run.templateName, style: run.style, statusLabelZh: run.status.labelZh, progressPercent: run.status == .running ? 50 : 0, realizedPnlUsd: run.realizedPnlUsd)
            }
            haptics.impact(.light)
        } catch {
            haptics.error()
            runActionErrors[runId] = Self.message(for: error)
        }
    }

    /// 将仓库返回的最新运行实例合并进现有列表，避免整次 reload 引入的竞态或闪烁。
    private func applyRunLocally(_ run: TemplateRun) {
        guard case .loaded(var list) = runs else {
            Task { await loadRuns() }
            return
        }
        if let index = list.firstIndex(where: { $0.id == run.id }) {
            list[index] = run
        } else {
            list.insert(run, at: 0)
        }
        runs = .loaded(list)
        syncWidgetSnapshot(list)
    }

    private static func message(for error: Error) -> String {
        if let envelope = error as? APIErrorEnvelope { return envelope.message }
        return error.localizedDescription
    }

    /// 供 `RunDetailView` 按 runId 独立拉取订单，返回值由视图自持有的 `@State` 承接，
    /// 避免共享单一状态在快速切换详情页时产生覆盖竞态。
    func fetchRunOrders(runId: String) async throws -> [TemplateOrderRow] {
        try await repository.fetchRunOrders(runId: runId)
    }

    func fetchRunTicks(runId: String) async throws -> [TemplateRunTick] {
        try await repository.fetchRunTicks(runId: runId)
    }

    /// 在当前已加载的 `runs` 列表中查找某个运行实例的最新快照。
    func run(withId runId: String) -> TemplateRun? {
        guard case .loaded(let list) = runs else { return nil }
        return list.first { $0.id == runId }
    }

    /// 已加载的模板列表，供「策略回测」的模板切换菜单使用。
    var loadedTemplates: [StrategyTemplate] {
        guard case .loaded(let list) = templates else { return [] }
        return list
    }

    // MARK: - 回测

    func runBacktest() async {
        backtestResult = .loading
        aiResearch = .idle
        let activityId = "backtest-\(UUID().uuidString)"
        liveActivity?.startOrUpdateStrategyRun(
            runId: activityId, templateName: draft.name, style: draft.style, kind: .backtest,
            statusLabelZh: "回测中", progressPercent: 15, realizedPnlUsd: 0
        )
        do {
            let request = draft.toBacktestRequest()
            let result = try await repository.runBacktest(request)
            backtestResult = .loaded(result)
            notifications.notifyBacktestCompleted(templateName: draft.name, totalReturnPercent: result.summary.totalReturnPercent)
            liveActivity?.endActivity(
                runId: activityId, finalStatusLabelZh: "回测已完成",
                finalProgressPercent: 100, finalRealizedPnlUsd: result.summary.totalReturnPercent
            )
        } catch {
            backtestResult = .failed(error.localizedDescription)
            liveActivity?.endActivity(runId: activityId, finalStatusLabelZh: "回测失败")
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
    var cronExpression: String = "*/5 * * * *"
    var sizingUsd: Double = 500
    var leverage: Double = 1
    var takeProfitPercent: Double = 6
    var stopLossPercent: Double = 3
    var maxLeverage: Double = 5
    var bar: CandleInterval = .fifteenMinutes
    var ruleParams: [String: Double] = ["fastMa": 7, "slowMa": 25, "rsiPeriod": 14]

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
        cronExpression = template.frequency.cronExpression ?? cronExpression
        sizingUsd = template.entrySizing.usdAmount
        leverage = template.leverage
        takeProfitPercent = template.risk.takeProfitPercent
        stopLossPercent = template.risk.stopLossPercent
        maxLeverage = template.risk.maxLeverage
        if !template.ruleParams.isEmpty { ruleParams = template.ruleParams }
    }

    func toTemplate(existingId: String?) -> StrategyTemplate {
        StrategyTemplate(
            id: existingId ?? UUID().uuidString,
            name: name,
            style: style,
            instId: instId,
            instType: instType,
            frequency: StrategyFrequency(kind: frequencyKind, intervalSeconds: intervalSeconds, cronExpression: frequencyKind == .cron ? cronExpression : nil),
            entrySizing: EntrySizing(usdAmount: sizingUsd, percentOfEquity: nil),
            leverage: leverage,
            risk: RiskConfig(takeProfitPercent: takeProfitPercent, stopLossPercent: stopLossPercent, maxLeverage: maxLeverage),
            ruleParams: ruleParams,
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
