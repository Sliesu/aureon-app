//
//  WidgetSnapshotStore.swift
//  aureon-app
//
//  将脱敏后的自选/策略摘要写入共享存储，供未来 Widget Extension 读取。
//  当前使用 UserDefaults.standard；若创建了真正的 Widget Extension Target，
//  应改为 App Group 容器（需要在 Xcode 中开启 App Groups 能力并在开发者账号
//  注册组标识符），这一步无法在无 GUI 的云端环境中安全完成，详见 README。
//

import Foundation

struct WatchlistWidgetSnapshot: Codable {
    var instId: String
    var last: Double
    var changePercent24h: Double
}

struct StrategyWidgetSnapshot: Codable {
    var runningCount: Int
    var topTemplateName: String
    var topRealizedPnlUsd: Double
    var updatedAt: Date
}

enum WidgetSnapshotStore {
    private static let defaults = UserDefaults.standard
    private static let watchlistKey = "aureon.widget.watchlist"
    private static let strategyKey = "aureon.widget.strategy"

    static func updateWatchlist(_ items: [WatchlistWidgetSnapshot]) {
        guard let data = try? AureonJSON.encoder.encode(items) else { return }
        defaults.set(data, forKey: watchlistKey)
    }

    static func readWatchlist() -> [WatchlistWidgetSnapshot] {
        guard let data = defaults.data(forKey: watchlistKey) else { return [] }
        return (try? AureonJSON.decoder.decode([WatchlistWidgetSnapshot].self, from: data)) ?? []
    }

    static func updateStrategySummary(_ snapshot: StrategyWidgetSnapshot) {
        guard let data = try? AureonJSON.encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: strategyKey)
    }

    static func readStrategySummary() -> StrategyWidgetSnapshot? {
        guard let data = defaults.data(forKey: strategyKey) else { return nil }
        return try? AureonJSON.decoder.decode(StrategyWidgetSnapshot.self, from: data)
    }
}
