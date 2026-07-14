//
//  CommonModels.swift
//  aureon-app
//
//  跨域共享的枚举与基础模型，对齐 Web 版 workspace-defaults / product-scope / risk-config。
//

import Foundation

enum TradingMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case spot
    case derivatives
    case both

    var id: String { rawValue }
    var labelZh: String {
        switch self {
        case .spot: return "仅现货"
        case .derivatives: return "仅衍生品"
        case .both: return "现货 + 衍生品"
        }
    }
}

enum AutomationMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case fullAuto = "full_auto"
    case suggestOnly = "suggest_only"
    case hybrid

    var id: String { rawValue }
    var labelZh: String {
        switch self {
        case .fullAuto: return "全自动"
        case .suggestOnly: return "仅建议"
        case .hybrid: return "混合模式"
        }
    }
}

enum TenantMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case singleUser = "single_user"
    case multiTenant = "multi_tenant"

    var id: String { rawValue }
    var labelZh: String {
        switch self {
        case .singleUser: return "单用户"
        case .multiTenant: return "多租户（MVP 未完整实现）"
        }
    }
}

struct WorkspaceScope: Codable, Equatable {
    var tradingMode: TradingMode
    var automationMode: AutomationMode
    var tenantMode: TenantMode

    static let `default` = WorkspaceScope(tradingMode: .both, automationMode: .hybrid, tenantMode: .singleUser)
}

struct RiskLimits: Codable, Equatable {
    var maxOrderNotionalUsd: Double
    var maxDailyLossUsd: Double
    var maxPositionNotionalUsd: Double
    var cooldownMs: Int
    var hybridAutoMaxNotionalUsd: Double
    var maxLeverage: Double
    var maxOpenPositions: Int

    static let `default` = RiskLimits(
        maxOrderNotionalUsd: 500,
        maxDailyLossUsd: 200,
        maxPositionNotionalUsd: 2_000,
        cooldownMs: 15_000,
        hybridAutoMaxNotionalUsd: 100,
        maxLeverage: 5,
        maxOpenPositions: 4
    )
}

struct RiskSnapshot: Codable, Equatable {
    var positionNotionalUsd: Double
    var dailyRealizedPnlUsd: Double
    var lastOrderAt: Date?

    static let empty = RiskSnapshot(positionNotionalUsd: 0, dailyRealizedPnlUsd: 0, lastOrderAt: nil)
}

enum QuoteCurrency: String, Codable, CaseIterable, Identifiable, Hashable {
    case usdt = "USDT"
    case usd = "USD"
    case cny = "CNY"

    var id: String { rawValue }
}

struct DisplayPreferences: Codable, Equatable {
    var quoteCurrency: QuoteCurrency
    var decimalPlaces: Int
    var smallAmountThreshold: Double

    static let `default` = DisplayPreferences(quoteCurrency: .usdt, decimalPlaces: 2, smallAmountThreshold: 1)
}

enum InstrumentType: String, Codable, CaseIterable, Identifiable, Hashable {
    case spot = "SPOT"
    case swap = "SWAP"

    var id: String { rawValue }
    var labelZh: String { self == .spot ? "现货" : "永续合约" }
}

enum OrderSide: String, Codable, CaseIterable, Identifiable, Hashable {
    case buy
    case sell

    var id: String { rawValue }
    var labelZh: String { self == .buy ? "买入" : "卖出" }
}

enum AdviceAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case buy
    case sell
    case hold

    var id: String { rawValue }
    var labelZh: String {
        switch self {
        case .buy: return "建议买入"
        case .sell: return "建议卖出"
        case .hold: return "建议观望"
        }
    }
}

/// 统一 API 错误信封，对齐后端 envelope（code + message + 可选详情）。
struct APIErrorEnvelope: Codable, Error, Equatable {
    var code: String
    var message: String
    var details: [String: String]?
}

enum RiskRejectionReason: String, Codable, Hashable {
    case notionalExceeded = "order_notional_exceeded"
    case dailyLossExceeded = "daily_loss_exceeded"
    case positionExceeded = "position_notional_exceeded"
    case cooldownActive = "cooldown_active"
    case leverageExceeded = "leverage_exceeded"
    case openPositionsExceeded = "max_open_positions_exceeded"
    case suggestOnlyBlocked = "suggest_only_blocked"
    case credentialsNotConfigured = "credentials_not_configured"

    var messageZh: String {
        switch self {
        case .notionalExceeded: return "订单名义金额超出单笔上限"
        case .dailyLossExceeded: return "已触发日内亏损熔断"
        case .positionExceeded: return "持仓名义金额超出上限"
        case .cooldownActive: return "交易冷却时间尚未结束"
        case .leverageExceeded: return "杠杆超出允许上限"
        case .openPositionsExceeded: return "持仓数量已达上限"
        case .suggestOnlyBlocked: return "当前为仅建议模式，已阻断自动执行"
        case .credentialsNotConfigured: return "OKX 凭据尚未配置"
        }
    }
}

/// 通用异步加载态容器，供各 ViewModel 复用。
enum LoadState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(String)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
