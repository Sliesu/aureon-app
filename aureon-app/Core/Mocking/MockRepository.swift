//
//  MockRepository.swift
//  aureon-app
//
//  完全离线可运行的数据仓库实现。持有内存状态以支持增删改（模板、运行、
//  自选、Pilot 会话等），使 App 在没有任何网络连接的情况下也能完整演示。
//

import Foundation

actor MockRepository: DataRepository {
    private var scope = WorkspaceScope.default
    private var riskLimits = RiskLimits.default
    private var displayPrefs = DisplayPreferences.default
    private var riskSnapshot = RiskSnapshot(positionNotionalUsd: 16_772, dailyRealizedPnlUsd: 214.6, lastOrderAt: Date().addingTimeInterval(-1_800))

    private var watchlist: [WatchlistItem] = [
        WatchlistItem(instId: "BTC-USDT", addedAt: Date().addingTimeInterval(-86_400 * 3)),
        WatchlistItem(instId: "ETH-USDT", addedAt: Date().addingTimeInterval(-86_400 * 2)),
        WatchlistItem(instId: "SOL-USDT", addedAt: Date().addingTimeInterval(-86_400))
    ]

    private var templates: [StrategyTemplate] = MockStrategyFactory.defaultTemplates()
    private var runs: [TemplateRun] = MockStrategyFactory.defaultRuns()
    private var pilotSessions: [AiPilotSession] = MockPilotFactory.sessions()
    private var adviceHistory: [AdviceRecord] = MockAdviceFactory.history()

    private let scenarioProvider: @Sendable () -> MockScenario

    init(scenarioProvider: @escaping @Sendable () -> MockScenario = { .normal }) {
        self.scenarioProvider = scenarioProvider
    }

    private func simulateLatency() async {
        try? await Task.sleep(nanoseconds: 260_000_000)
    }

    private func guardScenario() throws {
        switch scenarioProvider() {
        case .serviceError:
            throw NetworkError.server(APIErrorEnvelope(code: "mock_service_error", message: "演示场景：模拟服务端错误", details: nil))
        case .offline:
            throw NetworkError.offline
        default:
            break
        }
    }

    // MARK: - 系统 / 设置

    func fetchSettings() async throws -> SettingsPayload {
        await simulateLatency()
        try guardScenario()
        return SettingsPayload(
            scope: scope,
            riskLimits: riskLimits,
            riskSnapshot: riskSnapshot,
            strategyConfig: StrategyGlobalConfig(enabled: true, instId: "BTC-USDT", pollMs: 4_000),
            displayPrefs: displayPrefs,
            pilotMinDecisionGapMs: 900_000,
            runtimeConnectors: RuntimeConnectorSnapshot(llmConfigured: true, okxConfigured: true, okxSimulated: true, marketIntelConfigured: true),
            appVersion: "0.9.0"
        )
    }

    func updateScope(_ newScope: WorkspaceScope) async throws -> SettingsPayload {
        scope = newScope
        return try await fetchSettings()
    }

    func updateRiskLimits(_ limits: RiskLimits) async throws -> SettingsPayload {
        riskLimits = limits
        return try await fetchSettings()
    }

    func updateDisplayPrefs(_ prefs: DisplayPreferences) async throws -> SettingsPayload {
        displayPrefs = prefs
        return try await fetchSettings()
    }

    func fetchReleaseNotes() async throws -> [ReleaseNote] {
        [
            ReleaseNote(id: "0.9.0", version: "0.9.0", date: Date(), highlightsZh: ["原生 iOS 首个版本上线", "乌木金纹设计系统与液态玻璃 Dock", "策略回测与纸面运行本地化"]),
            ReleaseNote(id: "0.8.1", version: "0.8.1", date: Date().addingTimeInterval(-86_400 * 30), highlightsZh: ["Web 版账户流水分页优化", "AI Pilot 决策节流"])
        ]
    }

    // MARK: - 市场

    func fetchWatchlist() async throws -> [WatchlistItem] {
        await simulateLatency()
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return watchlist
    }

    func toggleWatchlist(instId: String, add: Bool) async throws -> [WatchlistItem] {
        if add, !watchlist.contains(where: { $0.instId == instId }) {
            watchlist.append(WatchlistItem(instId: instId, addedAt: .now))
        } else if !add {
            watchlist.removeAll { $0.instId == instId }
        }
        return watchlist
    }

    func fetchTicker(instId: String) async throws -> TickerSnapshot {
        try guardScenario()
        return MockMarketFactory.ticker(instId: instId)
    }

    func fetchCandles(instId: String, bar: CandleInterval, limit: Int) async throws -> [Candle] {
        await simulateLatency()
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return MockMarketFactory.candles(instId: instId, bar: bar, limit: limit)
    }

    func fetchPriceSeries(instId: String) async throws -> [PricePoint] {
        let candles = MockMarketFactory.candles(instId: instId, bar: .fiveMinutes, limit: 60)
        return candles.map { PricePoint(t: $0.ts, last: $0.close) }
    }

    func fetchVolatilityStrip() async throws -> [VolatilityStripItem] {
        try guardScenario()
        return MockMarketFactory.volatilityStrip()
    }

    func fetchMacro() async throws -> MacroSnapshot {
        try guardScenario()
        return MockMarketFactory.macro()
    }

    func fetchHeadlines() async throws -> [HeadlineItem] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return MockMarketFactory.headlines()
    }

    func fetchMarketIntel(instId: String) async throws -> MarketIntelSnapshot {
        try guardScenario()
        return MockMarketFactory.marketIntel(instId: instId)
    }

    func fetchOrderBook(instId: String) async throws -> OrderBookSnapshot {
        try guardScenario()
        return MockMarketFactory.orderBook(instId: instId)
    }

    func fetchFundingRate(instId: String) async throws -> FundingRateInfo {
        try guardScenario()
        return MockMarketFactory.fundingRate(instId: instId)
    }

    func fetchInstruments() async throws -> [Instrument] {
        try guardScenario()
        return MockMarketFactory.supportedInstruments.map { instId in
            let ticker = MockMarketFactory.ticker(instId: instId)
            let parts = instId.split(separator: "-")
            return Instrument(
                instId: instId,
                instType: .spot,
                baseCcy: String(parts.first ?? ""),
                quoteCcy: String(parts.count > 1 ? parts[1] : ""),
                lastPrice: ticker.last,
                changePercent24h: ticker.changePercent24h
            )
        }
    }

    nonisolated func streamTicker(instId: String) -> AsyncStream<MarketStreamEvent> {
        MockTickerStreamSimulator.stream(instId: instId, scenarioProvider: scenarioProvider)
    }

    func analyzeCandles(instId: String, bar: CandleInterval) async throws -> String {
        await simulateLatency()
        try guardScenario()
        return "\(instId) 近期在 \(bar.labelZh) 周期呈现震荡上行结构，短期均线粘合，量能温和放大，若放量突破近期高点可关注延续机会；反之跌破均线簇则需警惕回调风险。（本摘要为本地演示 AI 生成，非投资建议）"
    }

    // MARK: - 账户

    func fetchBalances() async throws -> ([BalanceDetail], AccountSummary) {
        await simulateLatency()
        try guardScenario()
        if scenarioProvider() == .empty {
            return ([], AccountSummary(totalEquityUsd: 0, totalAvailableUsd: 0, totalFrozenUsd: 0, unrealizedPnlUsd: 0))
        }
        return MockAccountFactory.balances()
    }

    func fetchPositions(instType: InstrumentType?) async throws -> [Position] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        let positions = MockAccountFactory.positions()
        guard let instType else { return positions }
        return positions.filter { $0.instType == instType }
    }

    func fetchPendingOrders(instType: InstrumentType) async throws -> [PendingOrder] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return MockAccountFactory.pendingOrders().filter { $0.instType == instType }
    }

    func fetchOrders(instType: InstrumentType) async throws -> [OrderRecord] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return MockAccountFactory.orders().filter { $0.instType == instType }
    }

    func fetchFills(instType: InstrumentType) async throws -> [FillRecord] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return MockAccountFactory.fills()
    }

    func fetchBills() async throws -> [BillRecord] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return MockAccountFactory.bills()
    }

    // MARK: - 交易执行

    func placeOrder(instId: String, instType: InstrumentType, side: OrderSide, sizeUsd: Double, leverage: Double) async throws -> OrderRecord {
        await simulateLatency()
        if scenarioProvider() == .riskRejected {
            throw APIErrorEnvelope(code: RiskRejectionReason.notionalExceeded.rawValue, message: RiskRejectionReason.notionalExceeded.messageZh, details: nil)
        }
        try guardScenario()
        guard sizeUsd <= riskLimits.maxOrderNotionalUsd else {
            throw APIErrorEnvelope(code: RiskRejectionReason.notionalExceeded.rawValue, message: RiskRejectionReason.notionalExceeded.messageZh, details: nil)
        }
        if scope.automationMode == .suggestOnly {
            throw APIErrorEnvelope(code: RiskRejectionReason.suggestOnlyBlocked.rawValue, message: RiskRejectionReason.suggestOnlyBlocked.messageZh, details: nil)
        }
        let ticker = MockMarketFactory.ticker(instId: instId)
        riskSnapshot.lastOrderAt = .now
        riskSnapshot.positionNotionalUsd += sizeUsd
        return OrderRecord(
            id: UUID().uuidString,
            instId: instId,
            instType: instType,
            side: side,
            price: ticker.last,
            size: sizeUsd / max(ticker.last, 0.0001),
            filledSize: sizeUsd / max(ticker.last, 0.0001),
            state: .filled,
            createdAt: .now
        )
    }

    // MARK: - 策略

    func fetchStrategyPresets() async throws -> [StrategyPreset] {
        try guardScenario()
        return MockStrategyFactory.presets()
    }

    func fetchTemplates() async throws -> [StrategyTemplate] {
        await simulateLatency()
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return templates
    }

    func createTemplate(_ template: StrategyTemplate) async throws -> StrategyTemplate {
        var newTemplate = template
        if templates.contains(where: { $0.id == template.id }) {
            newTemplate.id = UUID().uuidString
        }
        templates.append(newTemplate)
        return newTemplate
    }

    func updateTemplate(_ template: StrategyTemplate) async throws -> StrategyTemplate {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else {
            throw APIErrorEnvelope(code: "not_found", message: "策略模板不存在", details: nil)
        }
        templates[index] = template
        return template
    }

    func deleteTemplate(id: String) async throws {
        templates.removeAll { $0.id == id }
    }

    func fetchRuns() async throws -> [TemplateRun] {
        await simulateLatency()
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return runs
    }

    func startRun(templateId: String) async throws -> TemplateRun {
        guard let template = templates.first(where: { $0.id == templateId }) else {
            throw APIErrorEnvelope(code: "not_found", message: "策略模板不存在", details: nil)
        }
        let run = TemplateRun(
            id: UUID().uuidString,
            templateId: template.id,
            templateName: template.name,
            style: template.style,
            instId: template.instId,
            status: .running,
            startedAt: .now,
            nextFireAt: Date().addingTimeInterval(Double(template.frequency.intervalSeconds)),
            execFailStreak: 0,
            lastTickAt: nil,
            realizedPnlUsd: 0
        )
        runs.insert(run, at: 0)
        return run
    }

    func setRunStatus(runId: String, status: RunStatus) async throws -> TemplateRun {
        guard let index = runs.firstIndex(where: { $0.id == runId }) else {
            throw APIErrorEnvelope(code: "not_found", message: "运行实例不存在", details: nil)
        }
        runs[index].status = status
        if status == .stopped || status == .completed { runs[index].nextFireAt = nil }
        return runs[index]
    }

    func fetchRunOrders(runId: String) async throws -> [TemplateOrderRow] {
        try guardScenario()
        return MockStrategyFactory.runOrders(runId: runId)
    }

    func fetchRunTicks(runId: String) async throws -> [TemplateRunTick] {
        try guardScenario()
        return MockStrategyFactory.runTicks(runId: runId)
    }

    // MARK: - 回测

    func runBacktest(_ request: BacktestRequest) async throws -> BacktestResult {
        try await Task.sleep(nanoseconds: 520_000_000)
        try guardScenario()
        return MockBacktestFactory.run(request)
    }

    func runWalkForward(_ request: BacktestRequest) async throws -> WalkForwardResult {
        try await Task.sleep(nanoseconds: 620_000_000)
        try guardScenario()
        return MockBacktestFactory.walkForward(request)
    }

    func runParamScan(_ request: BacktestRequest) async throws -> ParamScanResult {
        try await Task.sleep(nanoseconds: 620_000_000)
        try guardScenario()
        return MockBacktestFactory.paramScan(request)
    }

    // MARK: - AI Pilot

    func fetchPilotSessions() async throws -> [AiPilotSession] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return pilotSessions
    }

    func createPilotSession(_ session: AiPilotSession) async throws -> AiPilotSession {
        var newSession = session
        newSession.id = UUID().uuidString
        pilotSessions.append(newSession)
        return newSession
    }

    func setPilotStatus(sessionId: String, status: PilotSessionStatus) async throws -> AiPilotSession {
        guard let index = pilotSessions.firstIndex(where: { $0.id == sessionId }) else {
            throw APIErrorEnvelope(code: "not_found", message: "Pilot 会话不存在", details: nil)
        }
        pilotSessions[index].status = status
        return pilotSessions[index]
    }

    func fetchPilotDecisions(sessionId: String) async throws -> [AiPilotDecision] {
        try guardScenario()
        return MockPilotFactory.decisions(sessionId: sessionId)
    }

    func fetchPilotHoldings() async throws -> [PilotHolding] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return MockPilotFactory.holdings()
    }

    func fetchPilotPendingOrders() async throws -> [PilotOrder] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return MockPilotFactory.pendingOrders()
    }

    func cancelPilotOrder(id: String) async throws {
        try guardScenario()
    }

    // MARK: - 洞察

    func evaluateAdvice(instId: String) async throws -> AdviceRecord {
        try await Task.sleep(nanoseconds: 480_000_000)
        try guardScenario()
        var generator = SeededGenerator(seed: UInt64(Date().timeIntervalSince1970))
        let actions: [AdviceAction] = [.buy, .sell, .hold]
        let record = AdviceRecord(
            id: UUID().uuidString,
            instId: instId,
            action: actions[Int(generator.nextRange(0...2.999))],
            confidencePercent: generator.nextRange(45...82),
            riskFlags: generator.nextDouble() > 0.5 ? [AdviceRiskFlag(id: UUID().uuidString, labelZh: "波动率偏高")] : [],
            llmSummaryZh: "基于近期价量结构与资金费率生成的规则化信号，仅供参考，不构成投资建议。",
            createdAt: .now
        )
        adviceHistory.insert(record, at: 0)
        return record
    }

    func fetchAdviceHistory() async throws -> [AdviceRecord] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return adviceHistory
    }

    func fetchEvaluationMetrics() async throws -> AdviceEvaluationMetrics {
        .placeholder
    }

    func fetchAuditEvents() async throws -> [AuditEvent] {
        try guardScenario()
        if scenarioProvider() == .empty { return [] }
        return MockAdviceFactory.auditEvents()
    }
}
