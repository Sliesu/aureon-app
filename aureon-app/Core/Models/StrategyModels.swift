//
//  StrategyModels.swift
//  aureon-app
//
//  策略域模型：11 种策略风格、模板、运行、订单与 tick 日志。
//  对齐 Web 版 strategy-style-ui.ts 与 quant-types.ts。
//

import Foundation

enum StrategyStyle: String, Codable, CaseIterable, Identifiable, Hashable {
    case conservative
    case balanced
    case aggressive
    case swing
    case dcaGrid = "dca_grid"
    case scalper
    case turtle
    case dualMa = "dual_ma"
    case gridBreakout = "grid_breakout"
    case bbRevert = "bb_revert"
    case rangeRotate = "range_rotate"

    var id: String { rawValue }

    var titleZh: String {
        switch self {
        case .conservative: return "稳健型"
        case .balanced: return "均衡型"
        case .aggressive: return "激进型"
        case .swing: return "波段"
        case .dcaGrid: return "定投网格"
        case .scalper: return "剥头皮"
        case .turtle: return "海龟突破"
        case .dualMa: return "双均线"
        case .gridBreakout: return "网格突破"
        case .bbRevert: return "布林回归"
        case .rangeRotate: return "区间轮动"
        }
    }

    var descriptionZh: String {
        switch self {
        case .conservative: return "低频、严格风控，追求稳定小额收益。"
        case .balanced: return "在收益与风险之间取得平衡的默认配置。"
        case .aggressive: return "更高仓位与更宽止损，追求更大波段收益。"
        case .swing: return "中周期波段跟随趋势，减少高频噪音。"
        case .dcaGrid: return "网格化分批建仓，摊平成本。"
        case .scalper: return "极短周期高频进出，依赖低延迟执行。"
        case .turtle: return "经典海龟突破，追踪通道突破信号。"
        case .dualMa: return "快慢双均线交叉判断趋势拐点。"
        case .gridBreakout: return "结合网格与突破确认过滤假信号。"
        case .bbRevert: return "布林带极值回归策略，适合震荡市。"
        case .rangeRotate: return "区间上下轨轮动，适合窄幅盘整。"
        }
    }

    var accentGlyph: String {
        switch self {
        case .conservative: return "shield.lefthalf.filled"
        case .balanced: return "scale.3d"
        case .aggressive: return "flame.fill"
        case .swing: return "waveform.path"
        case .dcaGrid: return "square.grid.3x3.fill"
        case .scalper: return "bolt.fill"
        case .turtle: return "tortoise.fill"
        case .dualMa: return "arrow.triangle.branch"
        case .gridBreakout: return "square.stack.3d.up.fill"
        case .bbRevert: return "arrow.uturn.backward.circle.fill"
        case .rangeRotate: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

enum StrategyFrequencyKind: String, Codable, Hashable {
    case interval
    case cron
}

struct StrategyFrequency: Codable, Equatable {
    var kind: StrategyFrequencyKind
    var intervalSeconds: Int
    var cronExpression: String?
}

struct RiskConfig: Codable, Equatable {
    var takeProfitPercent: Double
    var stopLossPercent: Double
    var maxLeverage: Double
}

struct EntrySizing: Codable, Equatable {
    var usdAmount: Double
    var percentOfEquity: Double?
}

struct StrategyTemplate: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var style: StrategyStyle
    var instId: String
    var instType: InstrumentType
    var frequency: StrategyFrequency
    var entrySizing: EntrySizing
    var leverage: Double
    var risk: RiskConfig
    var ruleParams: [String: Double]
    var createdAt: Date
    var updatedAt: Date
    var lastBacktestSummary: BacktestSummary?
}

struct StrategyPreset: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var style: StrategyStyle
    var descriptionZh: String
}

enum RunStatus: String, Codable, CaseIterable, Hashable {
    case running
    case paused
    case stopped
    case completed
    case error

    var labelZh: String {
        switch self {
        case .running: return "运行中"
        case .paused: return "已暂停"
        case .stopped: return "已停止"
        case .completed: return "已完成"
        case .error: return "异常"
        }
    }

    var tintKey: SemanticTint {
        switch self {
        case .running: return .buy
        case .paused: return .hold
        case .stopped: return .hold
        case .completed: return .buy
        case .error: return .sell
        }
    }
}

struct TemplateRun: Codable, Equatable, Identifiable {
    var id: String
    var templateId: String
    var templateName: String
    var style: StrategyStyle
    var instId: String
    var status: RunStatus
    var startedAt: Date
    var nextFireAt: Date?
    var execFailStreak: Int
    var lastTickAt: Date?
    var realizedPnlUsd: Double
}

struct TemplateOrderRow: Codable, Equatable, Identifiable {
    var id: String
    var runId: String
    var side: OrderSide
    var price: Double
    var size: Double
    var createdAt: Date
}

struct TemplateRunTick: Codable, Equatable, Identifiable {
    var id: String
    var runId: String
    var occurredAt: Date
    var messageZh: String
    var signal: AdviceAction?
}

enum SemanticTint: String {
    case buy
    case sell
    case hold
}
