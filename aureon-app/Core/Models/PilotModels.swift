//
//  PilotModels.swift
//  aureon-app
//
//  AI Pilot 域模型：自主决策会话、决策日志、持仓与挂单。
//

import Foundation

enum PilotSessionStatus: String, Codable, CaseIterable, Hashable {
    case draft
    case running
    case paused
    case stopped

    var labelZh: String {
        switch self {
        case .draft: return "草稿"
        case .running: return "运行中"
        case .paused: return "已暂停"
        case .stopped: return "已停止"
        }
    }
}

struct AiPilotSession: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var instId: String
    var instType: InstrumentType
    var status: PilotSessionStatus
    var autoExecute: Bool
    var decisionGapSeconds: Int
    var createdAt: Date
    var lastDecisionAt: Date?
}

enum PilotDecisionAction: String, Codable, Hashable {
    case buy
    case sell
    case hold
    case closePosition = "close_position"

    var labelZh: String {
        switch self {
        case .buy: return "买入"
        case .sell: return "卖出"
        case .hold: return "观望"
        case .closePosition: return "平仓"
        }
    }
}

struct AiPilotDecision: Codable, Equatable, Identifiable {
    var id: String
    var sessionId: String
    var action: PilotDecisionAction
    var confidencePercent: Double
    var reasoningZh: String
    var executed: Bool
    var occurredAt: Date
}

struct PilotHolding: Codable, Equatable, Identifiable {
    var id: String
    var instId: String
    var quantity: Double
    var averagePrice: Double
    var markPrice: Double
    var unrealizedPnlUsd: Double
}

struct PilotOrder: Codable, Equatable, Identifiable {
    var id: String
    var instId: String
    var side: OrderSide
    var price: Double
    var size: Double
    var createdAt: Date
}
