//
//  LiveAPIClient.swift
//  aureon-app
//
//  面向未来真实后端的实现骨架。当前仓库未提供服务端，此客户端结构上完整
//  （URLSession + Codable + APIEndpoint 映射），但在未配置 baseURL 前始终
//  抛出 NetworkError.notConfigured，避免任何隐式网络访问。
//
//  切换方式：在「我的 → API 环境」中将数据源改为 .live 并填入 Base URL 后，
//  AppEnvironment 会以此客户端替换 MockRepository。
//

import Foundation

actor LiveAPIClient: DataRepository {
    private let baseURL: URL?
    private let session: URLSession

    init(baseURL: URL? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    private func request<T: Decodable>(_ endpoint: APIEndpoint, method: String = "GET", body: Encodable? = nil) async throws -> T {
        guard let baseURL else { throw NetworkError.notConfigured }
        var url = baseURL
        url.append(path: endpoint.path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            urlRequest.httpBody = try AureonJSON.encoder.encode(AnyEncodableBox(body))
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else { throw NetworkError.unknown("无效响应") }
            guard (200..<300).contains(http.statusCode) else {
                if let envelope = try? AureonJSON.decoder.decode(APIErrorEnvelope.self, from: data) {
                    throw NetworkError.server(envelope)
                }
                throw NetworkError.unknown("HTTP \(http.statusCode)")
            }
            return try AureonJSON.decoder.decode(T.self, from: data)
        } catch let error as NetworkError {
            throw error
        } catch is CancellationError {
            throw NetworkError.timeout
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }

    // MARK: - 系统 / 设置

    func fetchSettings() async throws -> SettingsPayload { try await request(.settings) }
    func updateScope(_ scope: WorkspaceScope) async throws -> SettingsPayload { try await request(.settings, method: "PATCH", body: scope) }
    func updateRiskLimits(_ limits: RiskLimits) async throws -> SettingsPayload { try await request(.settings, method: "PATCH", body: limits) }
    func updateDisplayPrefs(_ prefs: DisplayPreferences) async throws -> SettingsPayload { try await request(.settings, method: "PATCH", body: prefs) }
    func fetchReleaseNotes() async throws -> [ReleaseNote] { throw NetworkError.notConfigured }

    // MARK: - 市场

    func fetchWatchlist() async throws -> [WatchlistItem] { try await request(.watchlist) }
    func toggleWatchlist(instId: String, add: Bool) async throws -> [WatchlistItem] {
        try await request(.watchlist, method: "POST", body: ["instId": instId, "op": add ? "add" : "remove"])
    }
    func fetchTicker(instId: String) async throws -> TickerSnapshot { try await request(.ticker(instId: instId)) }
    func fetchCandles(instId: String, bar: CandleInterval, limit: Int) async throws -> [Candle] {
        try await request(.ohlcv(instId: instId, bar: bar.rawValue, limit: limit))
    }
    func fetchPriceSeries(instId: String) async throws -> [PricePoint] { try await request(.series(instId: instId)) }
    func fetchVolatilityStrip() async throws -> [VolatilityStripItem] { try await request(.volatilityStrip) }
    func fetchMacro() async throws -> MacroSnapshot { try await request(.macro) }
    func fetchHeadlines() async throws -> [HeadlineItem] { try await request(.headlines) }
    func fetchMarketIntel(instId: String) async throws -> MarketIntelSnapshot { try await request(.intelPreview(instId: instId)) }
    func fetchOrderBook(instId: String) async throws -> OrderBookSnapshot { try await request(.orderBook(instId: instId)) }
    func fetchFundingRate(instId: String) async throws -> FundingRateInfo { try await request(.funding(instId: instId)) }
    func fetchInstruments() async throws -> [Instrument] { try await request(.instruments) }

    nonisolated func streamTicker(instId: String) -> AsyncStream<MarketStreamEvent> {
        AsyncStream { continuation in
            guard baseURL != nil else {
                continuation.yield(.error("尚未配置真实后端 Base URL"))
                continuation.finish()
                return
            }
            // 真实实现应基于 URLSession bytes(for:) 逐行解析 SSE `data:` 帧；
            // 结构预留，当前无可用服务端故不建立连接。
            continuation.yield(.disconnected)
            continuation.finish()
        }
    }

    func analyzeCandles(instId: String, bar: CandleInterval) async throws -> String {
        struct Response: Decodable { let summaryZh: String }
        let response: Response = try await request(.candlesAnalyze, method: "POST", body: ["instId": instId, "bar": bar.rawValue])
        return response.summaryZh
    }

    // MARK: - 账户

    func fetchBalances() async throws -> ([BalanceDetail], AccountSummary) {
        struct Response: Decodable { let details: [BalanceDetail]; let summary: AccountSummary }
        let response: Response = try await request(.accountBalance)
        return (response.details, response.summary)
    }
    func fetchPositions(instType: InstrumentType?) async throws -> [Position] { try await request(.accountPositions) }
    func fetchPendingOrders(instType: InstrumentType) async throws -> [PendingOrder] { try await request(.accountOrdersPending) }
    func fetchOrders(instType: InstrumentType) async throws -> [OrderRecord] { try await request(.accountOrders) }
    func fetchFills(instType: InstrumentType) async throws -> [FillRecord] { try await request(.accountFills) }
    func fetchBills() async throws -> [BillRecord] { try await request(.accountBills) }

    // MARK: - 交易执行

    func placeOrder(instId: String, instType: InstrumentType, side: OrderSide, sizeUsd: Double, leverage: Double) async throws -> OrderRecord {
        try await request(.execute, method: "POST", body: [
            "instId": instId, "instType": instType.rawValue, "side": side.rawValue,
            "sizeUsd": String(sizeUsd), "leverage": String(leverage)
        ])
    }

    // MARK: - 策略

    func fetchStrategyPresets() async throws -> [StrategyPreset] { try await request(.strategyPresets) }
    func fetchTemplates() async throws -> [StrategyTemplate] { try await request(.strategyTemplates) }
    func createTemplate(_ template: StrategyTemplate) async throws -> StrategyTemplate { try await request(.strategyTemplates, method: "POST", body: template) }
    func updateTemplate(_ template: StrategyTemplate) async throws -> StrategyTemplate { try await request(.strategyTemplate(id: template.id), method: "PATCH", body: template) }
    func deleteTemplate(id: String) async throws { let _: EmptyResponse = try await request(.strategyTemplate(id: id), method: "DELETE") }
    func fetchRuns() async throws -> [TemplateRun] { try await request(.strategyRuns) }
    func startRun(templateId: String) async throws -> TemplateRun { try await request(.strategyRuns, method: "POST", body: ["templateId": templateId]) }
    func setRunStatus(runId: String, status: RunStatus) async throws -> TemplateRun {
        try await request(.strategyRunLifecycle(id: runId, action: status.rawValue), method: "POST")
    }
    func fetchRunOrders(runId: String) async throws -> [TemplateOrderRow] { try await request(.strategyRunOrders(id: runId)) }
    func fetchRunTicks(runId: String) async throws -> [TemplateRunTick] { try await request(.strategyRunTicks(id: runId)) }

    // MARK: - 回测

    func runBacktest(_ request: BacktestRequest) async throws -> BacktestResult { try await self.request(.backtest, method: "POST", body: request) }
    func runWalkForward(_ request: BacktestRequest) async throws -> WalkForwardResult { try await self.request(.backtestWalkForward, method: "POST", body: request) }
    func runParamScan(_ request: BacktestRequest) async throws -> ParamScanResult { try await self.request(.backtestScan, method: "POST", body: request) }

    // MARK: - AI Pilot

    func fetchPilotSessions() async throws -> [AiPilotSession] { try await request(.pilotSessions) }
    func createPilotSession(_ session: AiPilotSession) async throws -> AiPilotSession { try await request(.pilotSessions, method: "POST", body: session) }
    func setPilotStatus(sessionId: String, status: PilotSessionStatus) async throws -> AiPilotSession {
        try await request(.pilotSessionLifecycle(id: sessionId, action: status.rawValue), method: "POST")
    }
    func fetchPilotDecisions(sessionId: String) async throws -> [AiPilotDecision] { try await request(.pilotLog(id: sessionId)) }
    func fetchPilotHoldings() async throws -> [PilotHolding] { try await request(.pilotHoldings) }
    func fetchPilotPendingOrders() async throws -> [PilotOrder] { try await request(.pilotOrdersPending) }
    func cancelPilotOrder(id: String) async throws { let _: EmptyResponse = try await request(.pilotOrdersCancel, method: "POST", body: ["id": id]) }

    // MARK: - 洞察

    func evaluateAdvice(instId: String) async throws -> AdviceRecord { try await request(.advice, method: "POST", body: ["instId": instId]) }
    func fetchAdviceHistory() async throws -> [AdviceRecord] { try await request(.advice) }
    func fetchEvaluationMetrics() async throws -> AdviceEvaluationMetrics { .placeholder }
    func fetchAuditEvents() async throws -> [AuditEvent] { try await request(.audit) }
}

private struct EmptyResponse: Decodable {}

/// 类型抹除的 Encodable 包装，供泛型请求体使用。
private struct AnyEncodableBox: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}

extension URL {
    mutating func append(path: String) {
        if let combined = URL(string: path, relativeTo: self) {
            self = combined
        }
    }
}
