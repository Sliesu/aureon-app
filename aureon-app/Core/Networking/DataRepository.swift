//
//  DataRepository.swift
//  aureon-app
//
//  应用层数据仓库协议：五大功能域的统一数据访问接口。
//  MockRepository（离线演示）与 LiveAPIClient（未来真实后端）均遵循此协议，
//  ViewModel 层完全不感知底层数据来源，端点映射详见 Docs/API.md。
//

import Foundation

protocol DataRepository: Sendable {
    // 系统 / 设置
    func fetchSettings() async throws -> SettingsPayload
    func updateScope(_ scope: WorkspaceScope) async throws -> SettingsPayload
    func updateRiskLimits(_ limits: RiskLimits) async throws -> SettingsPayload
    func updateDisplayPrefs(_ prefs: DisplayPreferences) async throws -> SettingsPayload
    func fetchReleaseNotes() async throws -> [ReleaseNote]

    // 市场
    func fetchWatchlist() async throws -> [WatchlistItem]
    func toggleWatchlist(instId: String, add: Bool) async throws -> [WatchlistItem]
    func fetchTicker(instId: String) async throws -> TickerSnapshot
    func fetchCandles(instId: String, bar: CandleInterval, limit: Int) async throws -> [Candle]
    func fetchPriceSeries(instId: String) async throws -> [PricePoint]
    func fetchVolatilityStrip() async throws -> [VolatilityStripItem]
    func fetchMacro() async throws -> MacroSnapshot
    func fetchHeadlines() async throws -> [HeadlineItem]
    func fetchMarketIntel(instId: String) async throws -> MarketIntelSnapshot
    func fetchOrderBook(instId: String) async throws -> OrderBookSnapshot
    func fetchFundingRate(instId: String) async throws -> FundingRateInfo
    func fetchInstruments() async throws -> [Instrument]
    func streamTicker(instId: String) async -> AsyncStream<MarketStreamEvent>
    func analyzeCandles(instId: String, bar: CandleInterval) async throws -> String

    // 账户
    func fetchBalances() async throws -> ([BalanceDetail], AccountSummary)
    func fetchPositions(instType: InstrumentType?) async throws -> [Position]
    func fetchPendingOrders(instType: InstrumentType) async throws -> [PendingOrder]
    func fetchOrders(instType: InstrumentType) async throws -> [OrderRecord]
    func fetchFills(instType: InstrumentType) async throws -> [FillRecord]
    func fetchBills() async throws -> [BillRecord]

    // 交易执行
    func placeOrder(instId: String, instType: InstrumentType, side: OrderSide, sizeUsd: Double, leverage: Double) async throws -> OrderRecord

    // 策略
    func fetchStrategyPresets() async throws -> [StrategyPreset]
    func fetchTemplates() async throws -> [StrategyTemplate]
    func createTemplate(_ template: StrategyTemplate) async throws -> StrategyTemplate
    func updateTemplate(_ template: StrategyTemplate) async throws -> StrategyTemplate
    func deleteTemplate(id: String) async throws
    func fetchRuns() async throws -> [TemplateRun]
    func startRun(templateId: String) async throws -> TemplateRun
    func setRunStatus(runId: String, status: RunStatus) async throws -> TemplateRun
    func fetchRunOrders(runId: String) async throws -> [TemplateOrderRow]
    func fetchRunTicks(runId: String) async throws -> [TemplateRunTick]

    // 回测
    func runBacktest(_ request: BacktestRequest) async throws -> BacktestResult
    func runWalkForward(_ request: BacktestRequest) async throws -> WalkForwardResult
    func runParamScan(_ request: BacktestRequest) async throws -> ParamScanResult

    // AI Pilot
    func fetchPilotSessions() async throws -> [AiPilotSession]
    func createPilotSession(_ session: AiPilotSession) async throws -> AiPilotSession
    func setPilotStatus(sessionId: String, status: PilotSessionStatus) async throws -> AiPilotSession
    func fetchPilotDecisions(sessionId: String) async throws -> [AiPilotDecision]
    func fetchPilotHoldings() async throws -> [PilotHolding]
    func fetchPilotPendingOrders() async throws -> [PilotOrder]
    func cancelPilotOrder(id: String) async throws

    // 洞察
    func evaluateAdvice(instId: String) async throws -> AdviceRecord
    func fetchAdviceHistory() async throws -> [AdviceRecord]
    func fetchEvaluationMetrics() async throws -> AdviceEvaluationMetrics
    func fetchAuditEvents() async throws -> [AuditEvent]
}
