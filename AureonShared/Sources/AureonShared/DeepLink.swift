//
//  DeepLink.swift
//  AureonShared
//
//  统一深链模型：桌面快捷操作（Quick Actions）、桌面小组件点击、
//  灵动岛点击、本地通知点击均编码为同一个 `aureon://` URL /
//  `AureonDeepLink`，由主 App 的 AppRouter 统一解析与路由，
//  避免三处入口各自维护跳转逻辑。
//

import Foundation

public enum AureonDeepLink: Equatable, Hashable, Sendable {
    case market(instId: String)
    case strategyRuns
    case strategyNewTemplate
    case notificationSettings

    public static let urlScheme = "aureon"

    public var url: URL {
        var components = URLComponents()
        components.scheme = Self.urlScheme
        switch self {
        case .market(let instId):
            components.host = "market"
            components.path = "/\(instId)"
        case .strategyRuns:
            components.host = "strategy"
            components.path = "/runs"
        case .strategyNewTemplate:
            components.host = "strategy"
            components.path = "/new"
        case .notificationSettings:
            components.host = "settings"
            components.path = "/notifications"
        }
        return components.url ?? URL(string: "\(Self.urlScheme)://")!
    }

    public init?(url: URL) {
        guard url.scheme == Self.urlScheme, let host = url.host else { return nil }
        let path = url.path
        switch host {
        case "market":
            let instId = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !instId.isEmpty else { return nil }
            self = .market(instId: instId)
        case "strategy":
            if path == "/new" {
                self = .strategyNewTemplate
            } else {
                self = .strategyRuns
            }
        case "settings":
            self = .notificationSettings
        default:
            return nil
        }
    }

    /// 从通知 `userInfo["aureon.deepLink"]` 还原路由。
    public init?(userInfoValue: String?) {
        guard let userInfoValue, let url = URL(string: userInfoValue) else { return nil }
        self.init(url: url)
    }

    public var userInfoValue: String { url.absoluteString }
}

/// Home Screen Quick Actions（桌面长按快捷菜单）静态项标识符，
/// 主 App（注册 + 处理）与文档共用同一份定义。
public enum AureonQuickActionType: String, CaseIterable, Sendable {
    case openMarket = "com.rbc.aureon-app.quickaction.market"
    case openStrategyRuns = "com.rbc.aureon-app.quickaction.strategyRuns"
    case newStrategyTemplate = "com.rbc.aureon-app.quickaction.newTemplate"
    case notificationSettings = "com.rbc.aureon-app.quickaction.notificationSettings"

    public var deepLink: AureonDeepLink {
        switch self {
        case .openMarket: return .market(instId: "BTC-USDT")
        case .openStrategyRuns: return .strategyRuns
        case .newStrategyTemplate: return .strategyNewTemplate
        case .notificationSettings: return .notificationSettings
        }
    }

    public var titleZh: String {
        switch self {
        case .openMarket: return "市场行情"
        case .openStrategyRuns: return "运行中策略"
        case .newStrategyTemplate: return "新建策略"
        case .notificationSettings: return "通知设置"
        }
    }

    public var subtitleZh: String {
        switch self {
        case .openMarket: return "查看 BTC-USDT 实时行情"
        case .openStrategyRuns: return "查看当前运行实例"
        case .newStrategyTemplate: return "快速创建策略模板"
        case .notificationSettings: return "管理通知授权与偏好"
        }
    }

    public var systemImageName: String {
        switch self {
        case .openMarket: return "waveform.path.ecg"
        case .openStrategyRuns: return "chart.line.uptrend.xyaxis"
        case .newStrategyTemplate: return "plus.circle"
        case .notificationSettings: return "bell.badge"
        }
    }
}

/// 本地通知分类标识符，供 `NotificationManager` 与通知点击响应共用。
public enum AureonNotificationCategory: String, Sendable {
    case strategyStatus = "aureon.category.strategyStatus"
    case backtestCompleted = "aureon.category.backtestCompleted"
    case riskAlert = "aureon.category.riskAlert"
}
