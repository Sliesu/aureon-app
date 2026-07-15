//
//  StrategyActivityAttributes.swift
//  AureonShared
//
//  Live Activity 共享属性：策略运行 / 回测进度展示于锁屏与灵动岛。
//  主 App（发起/更新/结束 Activity）与 AureonWidgets Extension（渲染 UI）
//  必须使用完全相同的类型定义，故置于共享 Package 中。
//

import ActivityKit
import Foundation

public struct AureonStrategyActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var statusLabelZh: String
        public var progressPercent: Double
        public var realizedPnlUsd: Double
        public var updatedAt: Date

        public init(statusLabelZh: String, progressPercent: Double, realizedPnlUsd: Double, updatedAt: Date) {
            self.statusLabelZh = statusLabelZh
            self.progressPercent = progressPercent
            self.realizedPnlUsd = realizedPnlUsd
            self.updatedAt = updatedAt
        }
    }

    public var templateName: String
    public var style: String
    public var kind: ActivityKind
    public var runId: String

    public enum ActivityKind: String, Codable {
        case strategyRun
        case backtest
    }

    public init(templateName: String, style: String, kind: ActivityKind, runId: String) {
        self.templateName = templateName
        self.style = style
        self.kind = kind
        self.runId = runId
    }
}
