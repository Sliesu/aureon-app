//
//  BacktestModels.swift
//  aureon-app
//
//  回测域模型：标准回测、Walk-forward、参数扫描与本地纸面运行。
//

import Foundation

struct BacktestRequest: Codable, Equatable {
    var instId: String
    var instType: InstrumentType
    var bar: CandleInterval
    var limit: Int
    var style: StrategyStyle
    var sizingUsd: Double
    var leverage: Double
    var risk: RiskConfig
}

struct BacktestSummary: Codable, Equatable {
    var totalReturnPercent: Double
    var winRatePercent: Double
    var maxDrawdownPercent: Double
    var sharpeRatio: Double
    var tradeCount: Int
    var completedAt: Date
}

struct EquityPoint: Codable, Equatable, Identifiable {
    var t: Date
    var equity: Double
    var id: Date { t }
}

struct TradeRecord: Codable, Equatable, Identifiable {
    var id: String
    var entryAt: Date
    var exitAt: Date
    var side: OrderSide
    var entryPrice: Double
    var exitPrice: Double
    var pnlPercent: Double
    var isWin: Bool
}

struct BacktestResult: Codable, Equatable {
    var request: BacktestRequest
    var summary: BacktestSummary
    var equityCurve: [EquityPoint]
    var trades: [TradeRecord]
    var candles: [Candle]
}

struct WalkForwardWindowResult: Codable, Equatable, Identifiable {
    var id: String
    var windowLabel: String
    var inSampleReturnPercent: Double
    var outSampleReturnPercent: Double
}

struct WalkForwardResult: Codable, Equatable {
    var windows: [WalkForwardWindowResult]
    var averageOutSampleReturnPercent: Double
}

struct ParamScanPoint: Codable, Equatable, Identifiable {
    var id: String
    var paramLabel: String
    var totalReturnPercent: Double
    var maxDrawdownPercent: Double
}

struct ParamScanResult: Codable, Equatable {
    var points: [ParamScanPoint]
    var bestPointId: String?
}

/// 本地纸面运行状态机（浏览器端等价逻辑：仅依赖 ticker 价格流，session 级、不持久化）。
enum PaperRunStatus: String, Equatable {
    case idle
    case running
    case stopped
}

struct PaperRunState: Equatable {
    var status: PaperRunStatus = .idle
    var equity: Double = 10_000
    var startingEquity: Double = 10_000
    var position: PaperPosition?
    var equityCurve: [EquityPoint] = []
    var trades: [TradeRecord] = []

    var totalReturnPercent: Double {
        guard startingEquity > 0 else { return 0 }
        return (equity - startingEquity) / startingEquity * 100
    }
}

struct PaperPosition: Equatable {
    var side: OrderSide
    var entryPrice: Double
    var size: Double
    var enteredAt: Date
}
