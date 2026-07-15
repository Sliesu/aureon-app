//
//  WidgetSnapshotStore.swift
//  AureonShared
//
//  将脱敏后的自选/策略摘要写入 App Group 共享容器，供 AureonWidgets Extension
//  的 Timeline Provider 读取。主 App 写入后应调用 `WidgetCenter.shared
//  .reloadTimelines(ofKind:)` 请求刷新（见主 App 侧 `WidgetRefreshCenter`）。
//

import Foundation

public struct WatchlistWidgetSnapshot: Codable, Equatable, Identifiable {
    public var instId: String
    public var last: Double
    public var changePercent24h: Double

    public var id: String { instId }

    public init(instId: String, last: Double, changePercent24h: Double) {
        self.instId = instId
        self.last = last
        self.changePercent24h = changePercent24h
    }
}

public struct StrategyWidgetSnapshot: Codable, Equatable {
    public var runningCount: Int
    public var topTemplateName: String
    public var topRealizedPnlUsd: Double
    public var updatedAt: Date

    public init(runningCount: Int, topTemplateName: String, topRealizedPnlUsd: Double, updatedAt: Date) {
        self.runningCount = runningCount
        self.topTemplateName = topTemplateName
        self.topRealizedPnlUsd = topRealizedPnlUsd
        self.updatedAt = updatedAt
    }
}

public enum WidgetSnapshotStore {
    private static var defaults: UserDefaults { AureonAppGroup.sharedDefaults }
    private static let watchlistKey = "aureon.widget.watchlist"
    private static let strategyKey = "aureon.widget.strategy"

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public static func updateWatchlist(_ items: [WatchlistWidgetSnapshot]) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: watchlistKey)
    }

    public static func readWatchlist() -> [WatchlistWidgetSnapshot] {
        guard let data = defaults.data(forKey: watchlistKey) else { return [] }
        return (try? decoder.decode([WatchlistWidgetSnapshot].self, from: data)) ?? []
    }

    /// 策略摘要采用可选值：无运行中策略时应写入 `nil`，避免旧快照残留导致
    /// Widget 显示已停止的策略「假装仍在运行」。
    public static func updateStrategySummary(_ snapshot: StrategyWidgetSnapshot?) {
        guard let snapshot else {
            defaults.removeObject(forKey: strategyKey)
            return
        }
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: strategyKey)
    }

    public static func readStrategySummary() -> StrategyWidgetSnapshot? {
        guard let data = defaults.data(forKey: strategyKey) else { return nil }
        return try? decoder.decode(StrategyWidgetSnapshot.self, from: data)
    }
}
