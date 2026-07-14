//
//  APIEndpoint.swift
//  aureon-app
//
//  真实后端端点映射，与 Docs/openapi.yaml 一一对应。当前仓库尚未实现服务端，
//  LiveAPIClient 仅在用户显式配置 baseURL 后才会发出请求，默认抛出 .notConfigured。
//

import Foundation

enum APIEndpoint {
    case health
    case scope
    case settings
    case watchlist
    case ticker(instId: String)
    case ohlcv(instId: String, bar: String, limit: Int)
    case series(instId: String)
    case volatilityStrip
    case macro
    case headlines
    case intelPreview(instId: String)
    case orderBook(instId: String)
    case funding(instId: String)
    case instruments
    case marketStream(instId: String)
    case candlesAnalyze
    case accountBalance
    case accountPositions
    case accountOrdersPending
    case accountOrders
    case accountFills
    case accountBills
    case execute
    case strategyPresets
    case strategyTemplates
    case strategyTemplate(id: String)
    case strategyRuns
    case strategyRunLifecycle(id: String, action: String)
    case strategyRunOrders(id: String)
    case strategyRunTicks(id: String)
    case backtest
    case backtestWalkForward
    case backtestScan
    case pilotSessions
    case pilotSessionLifecycle(id: String, action: String)
    case pilotLog(id: String)
    case pilotHoldings
    case pilotOrdersPending
    case pilotOrdersCancel
    case advice
    case audit

    var path: String {
        switch self {
        case .health: return "/api/health"
        case .scope: return "/api/scope"
        case .settings: return "/api/settings"
        case .watchlist: return "/api/watchlist"
        case .ticker(let instId): return "/api/market/ticker?instId=\(instId)"
        case .ohlcv(let instId, let bar, let limit): return "/api/market/ohlcv?instId=\(instId)&bar=\(bar)&limit=\(limit)"
        case .series(let instId): return "/api/market/series?instId=\(instId)"
        case .volatilityStrip: return "/api/market/volatility-strip"
        case .macro: return "/api/market/crypto-macro"
        case .headlines: return "/api/market/crypto-headlines"
        case .intelPreview(let instId): return "/api/market/intel-preview?instId=\(instId)"
        case .orderBook: return "/api/market/orderbook"
        case .funding(let instId): return "/api/market/funding?instId=\(instId)"
        case .instruments: return "/api/okx/instruments"
        case .marketStream(let instId): return "/api/market/stream?instId=\(instId)"
        case .candlesAnalyze: return "/api/ai/candles-analyze"
        case .accountBalance: return "/api/account/balance"
        case .accountPositions: return "/api/account/positions"
        case .accountOrdersPending: return "/api/account/orders-pending"
        case .accountOrders: return "/api/account/orders"
        case .accountFills: return "/api/account/fills"
        case .accountBills: return "/api/account/bills"
        case .execute: return "/api/execute"
        case .strategyPresets: return "/api/strategy/presets"
        case .strategyTemplates: return "/api/strategy/templates"
        case .strategyTemplate(let id): return "/api/strategy/templates/\(id)"
        case .strategyRuns: return "/api/strategy/runs"
        case .strategyRunLifecycle(let id, let action): return "/api/strategy/runs/\(id)/\(action)"
        case .strategyRunOrders(let id): return "/api/strategy/runs/\(id)/orders"
        case .strategyRunTicks(let id): return "/api/strategy/runs/\(id)/ticks"
        case .backtest: return "/api/strategy/backtest"
        case .backtestWalkForward: return "/api/strategy/backtest/walk-forward"
        case .backtestScan: return "/api/strategy/backtest/scan"
        case .pilotSessions: return "/api/ai/pilot/sessions"
        case .pilotSessionLifecycle(let id, let action): return "/api/ai/pilot/sessions/\(id)/\(action)"
        case .pilotLog(let id): return "/api/ai/pilot/sessions/\(id)/log"
        case .pilotHoldings: return "/api/ai/pilot/holdings"
        case .pilotOrdersPending: return "/api/ai/pilot/orders/pending"
        case .pilotOrdersCancel: return "/api/ai/pilot/orders/cancel"
        case .advice: return "/api/advice"
        case .audit: return "/api/audit"
        }
    }
}
