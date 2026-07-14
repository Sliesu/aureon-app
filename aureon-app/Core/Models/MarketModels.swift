//
//  MarketModels.swift
//  aureon-app
//
//  行情域模型：ticker、K 线、自选、SSE 事件、宏观与市场情报。
//  对齐 Web 版 src/lib/quant-types.ts 与 /api/market/* 响应结构。
//

import Foundation

struct TickerSnapshot: Codable, Equatable, Identifiable {
    var instId: String
    var last: Double
    var bid: Double
    var ask: Double
    var open24h: Double
    var high24h: Double
    var low24h: Double
    var vol24h: Double
    var ts: Date

    var id: String { instId }

    var changePercent24h: Double {
        guard open24h > 0 else { return 0 }
        return (last - open24h) / open24h * 100
    }

    var spread: Double { max(0, ask - bid) }
}

struct Candle: Codable, Equatable, Identifiable {
    var ts: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double

    var id: Date { ts }

    enum CodingKeys: String, CodingKey {
        case ts, open = "o", high = "h", low = "l", close = "c", volume = "vol"
    }
}

enum CandleInterval: String, Codable, CaseIterable, Identifiable, Hashable {
    case oneMinute = "1m"
    case fiveMinutes = "5m"
    case fifteenMinutes = "15m"
    case oneHour = "1H"
    case fourHours = "4H"
    case oneDay = "1D"

    var id: String { rawValue }
    var labelZh: String {
        switch self {
        case .oneMinute: return "1分"
        case .fiveMinutes: return "5分"
        case .fifteenMinutes: return "15分"
        case .oneHour: return "1时"
        case .fourHours: return "4时"
        case .oneDay: return "1日"
        }
    }
}

struct PricePoint: Codable, Equatable, Identifiable {
    var t: Date
    var last: Double
    var id: Date { t }
}

struct WatchlistItem: Codable, Equatable, Identifiable {
    var instId: String
    var addedAt: Date
    var id: String { instId }
}

struct Instrument: Codable, Equatable, Identifiable {
    var instId: String
    var instType: InstrumentType
    var baseCcy: String
    var quoteCcy: String
    var lastPrice: Double
    var changePercent24h: Double
    var id: String { instId }
}

/// SSE `/api/market/stream` 事件模型。
enum MarketStreamEvent: Equatable {
    case tick(TickerSnapshot)
    case error(String)
    case connected
    case disconnected
}

enum ConnectionLiveness: String {
    case live
    case polling
    case offline

    var labelZh: String {
        switch self {
        case .live: return "实时连接"
        case .polling: return "轮询模式"
        case .offline: return "已断线"
        }
    }
}

struct VolatilityStripItem: Codable, Equatable, Identifiable {
    var instId: String
    var changePercent24h: Double
    var id: String { instId }
}

struct MacroSnapshot: Codable, Equatable {
    var totalMarketCapUsd: Double
    var btcDominancePercent: Double
    var fearGreedIndex: Int
    var history: [MacroPoint]
}

struct MacroPoint: Codable, Equatable, Identifiable {
    var t: Date
    var value: Double
    var id: Date { t }
}

struct HeadlineItem: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var source: String
    var publishedAt: Date
    var url: String
}

struct MarketIntelSnapshot: Codable, Equatable {
    var instId: String
    var summaryZh: String
    var longShortRatio: Double
    var liquidations24hUsd: Double
    var fundingRatePercent: Double
}

struct OrderBookLevel: Codable, Equatable, Identifiable {
    var price: Double
    var size: Double
    var id: Double { price }
}

struct OrderBookSnapshot: Codable, Equatable {
    var instId: String
    var bids: [OrderBookLevel]
    var asks: [OrderBookLevel]
    var ts: Date
}

struct FundingRateInfo: Codable, Equatable {
    var instId: String
    var fundingRatePercent: Double
    var nextFundingAt: Date
}

struct FxRates: Codable, Equatable {
    var usdToCny: Double
}
