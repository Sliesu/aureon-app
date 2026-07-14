//
//  AureonStrategyActivityAttributes.swift
//  aureon-app
//
//  Live Activity 共享属性：策略运行 / 回测进度展示于灵动岛与锁屏。
//  该文件类型不含 @main，可安全放置于主 App Target；若要在锁屏/灵动岛
//  渲染自定义 UI，需要额外创建 Widget Extension Target 并引用
//  Widgets/AureonWidgetsPreview.swift 中的 ActivityConfiguration（见该文件头部说明）。
//

import ActivityKit
import Foundation

struct AureonStrategyActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var statusLabelZh: String
        var progressPercent: Double
        var realizedPnlUsd: Double
        var updatedAt: Date
    }

    var templateName: String
    var style: String
    var kind: ActivityKind

    enum ActivityKind: String, Codable {
        case strategyRun
        case backtest
    }
}
