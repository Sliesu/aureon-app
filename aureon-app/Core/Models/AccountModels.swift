//
//  AccountModels.swift
//  aureon-app
//
//  账户域模型：余额、持仓、委托、成交、资金流水。对齐 /api/account/*。
//

import Foundation

struct BalanceDetail: Codable, Equatable, Identifiable {
    var ccy: String
    var availableBalance: Double
    var frozenBalance: Double
    var equityUsd: Double
    var id: String { ccy }
}

struct AccountSummary: Codable, Equatable {
    var totalEquityUsd: Double
    var totalAvailableUsd: Double
    var totalFrozenUsd: Double
    var unrealizedPnlUsd: Double
}

struct Position: Codable, Equatable, Identifiable {
    var id: String
    var instId: String
    var instType: InstrumentType
    var side: PositionSide
    var quantity: Double
    var entryPrice: Double
    var markPrice: Double
    var leverage: Double
    var unrealizedPnlUsd: Double
    var marginUsd: Double

    var unrealizedPnlPercent: Double {
        guard marginUsd > 0 else { return 0 }
        return unrealizedPnlUsd / marginUsd * 100
    }
}

enum PositionSide: String, Codable, Hashable {
    case long
    case short

    var labelZh: String { self == .long ? "多头" : "空头" }
}

struct PendingOrder: Codable, Equatable, Identifiable {
    var id: String
    var instId: String
    var instType: InstrumentType
    var side: OrderSide
    var price: Double
    var size: Double
    var filledSize: Double
    var createdAt: Date
}

enum OrderState: String, Codable, Hashable {
    case live
    case filled
    case canceled
    case partiallyFilled = "partially_filled"

    var labelZh: String {
        switch self {
        case .live: return "挂单中"
        case .filled: return "已成交"
        case .canceled: return "已撤销"
        case .partiallyFilled: return "部分成交"
        }
    }
}

struct OrderRecord: Codable, Equatable, Identifiable {
    var id: String
    var instId: String
    var instType: InstrumentType
    var side: OrderSide
    var price: Double
    var size: Double
    var filledSize: Double
    var state: OrderState
    var createdAt: Date
}

struct FillRecord: Codable, Equatable, Identifiable {
    var id: String
    var instId: String
    var side: OrderSide
    var price: Double
    var size: Double
    var feeUsd: Double
    var filledAt: Date
}

enum BillType: String, Codable, Hashable {
    case trade
    case funding
    case transfer
    case fee

    var labelZh: String {
        switch self {
        case .trade: return "交易"
        case .funding: return "资金费"
        case .transfer: return "划转"
        case .fee: return "手续费"
        }
    }
}

struct BillRecord: Codable, Equatable, Identifiable {
    var id: String
    var ccy: String
    var type: BillType
    var amount: Double
    var balanceAfter: Double
    var occurredAt: Date
}

enum AccountTab: String, CaseIterable, Identifiable, Hashable {
    case assets
    case positions
    case pending
    case orders
    case fills
    case bills

    var id: String { rawValue }
    var titleZh: String {
        switch self {
        case .assets: return "资产"
        case .positions: return "持仓"
        case .pending: return "当前委托"
        case .orders: return "历史委托"
        case .fills: return "成交"
        case .bills: return "流水"
        }
    }
}
