//
//  AureonWidgetsPreview.swift
//  aureon-app
//
//  ⚠️ 该文件为 Widget/Live Activity 的「预制代码」，故意不标记 @main，
//  以便安全放置在主 App Target 中而不产生重复入口点冲突。
//
//  若要在设备主屏 / 灵动岛实际渲染这些 UI，需要在 Xcode 中：
//  1. File → New → Target → Widget Extension，命名如 AureonWidgets；
//  2. 勾选 “Include Live Activity”；
//  3. 将本文件与 Core/LiveActivity/AureonStrategyActivityAttributes.swift、
//     Core/Utilities/WidgetSnapshotStore.swift、Core/DesignSystem/* 加入新 Target；
//  4. 把下方 `AureonWidgetsBundle` 重命名为该 Target 的 @main 入口（WidgetBundle）。
//
//  这一步依赖 Xcode 的项目模型 GUI 操作，无法在当前无 Xcode 的云端环境中
//  以纯文本编辑 project.pbxproj 的方式安全自动化，故本次提交仅保证主 App
//  可独立编译运行，Widget 部分以“预制代码 + 操作说明”的形式交付。
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - 自选小组件

struct WatchlistWidgetEntry: TimelineEntry {
    let date: Date
    let items: [WatchlistWidgetSnapshot]
}

struct WatchlistWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchlistWidgetEntry {
        WatchlistWidgetEntry(date: .now, items: [WatchlistWidgetSnapshot(instId: "BTC-USDT", last: 64_820, changePercent24h: 1.8)])
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchlistWidgetEntry) -> Void) {
        completion(WatchlistWidgetEntry(date: .now, items: WidgetSnapshotStore.readWatchlist()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchlistWidgetEntry>) -> Void) {
        let entry = WatchlistWidgetEntry(date: .now, items: WidgetSnapshotStore.readWatchlist())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60))))
    }
}

struct WatchlistWidgetView: View {
    let entry: WatchlistWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AUREON 自选")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(AureonPalette.gold500)
            ForEach(entry.items.prefix(3), id: \.instId) { item in
                HStack {
                    Text(item.instId.replacingOccurrences(of: "-USDT", with: ""))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                    Spacer()
                    Text(AureonFormat.percent(item.changePercent24h, decimals: 1))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(item.changePercent24h >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                }
            }
        }
        .padding(12)
        .containerBackground(AureonPalette.ebony950.gradient, for: .widget)
    }
}

struct AureonWatchlistWidget: Widget {
    let kind = "AureonWatchlistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchlistWidgetProvider()) { entry in
            WatchlistWidgetView(entry: entry)
        }
        .configurationDisplayName("AUREON 自选")
        .description("展示自选交易对的实时涨跌摘要。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 策略摘要小组件

struct StrategyWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: StrategyWidgetSnapshot?
}

struct StrategyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> StrategyWidgetEntry {
        StrategyWidgetEntry(date: .now, snapshot: StrategyWidgetSnapshot(runningCount: 2, topTemplateName: "BTC 稳健定投", topRealizedPnlUsd: 214.6, updatedAt: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (StrategyWidgetEntry) -> Void) {
        completion(StrategyWidgetEntry(date: .now, snapshot: WidgetSnapshotStore.readStrategySummary()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StrategyWidgetEntry>) -> Void) {
        let entry = StrategyWidgetEntry(date: .now, snapshot: WidgetSnapshotStore.readStrategySummary())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60))))
    }
}

struct StrategyWidgetView: View {
    let entry: StrategyWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("策略运行中")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(AureonPalette.gold500)
            if let snapshot = entry.snapshot {
                Text("\(snapshot.runningCount) 个运行实例")
                    .font(.system(size: 13, weight: .medium))
                Text(snapshot.topTemplateName)
                    .font(.system(size: 12, design: .monospaced))
                Text(AureonFormat.currency(snapshot.topRealizedPnlUsd))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(snapshot.topRealizedPnlUsd >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
            } else {
                Text("暂无运行中的策略").font(.system(size: 12)).foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .padding(12)
        .containerBackground(AureonPalette.ebony950.gradient, for: .widget)
    }
}

struct AureonStrategyWidget: Widget {
    let kind = "AureonStrategyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StrategyWidgetProvider()) { entry in
            StrategyWidgetView(entry: entry)
        }
        .configurationDisplayName("AUREON 策略摘要")
        .description("展示运行中策略数量与最新已实现盈亏。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Live Activity（策略运行 / 回测进度）

@available(iOS 16.1, *)
struct AureonStrategyLiveActivityView: View {
    let context: ActivityViewContext<AureonStrategyActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(context.attributes.templateName)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(AureonPalette.gold500)
                Spacer()
                Text(context.state.statusLabelZh)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
            }
            ProgressView(value: context.state.progressPercent, total: 100)
                .tint(AureonPalette.gold500)
            Text(AureonFormat.currency(context.state.realizedPnlUsd))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(context.state.realizedPnlUsd >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
        }
        .padding(14)
        .activityBackgroundTint(AureonPalette.ebony950)
        .activitySystemActionForegroundColor(.white)
    }
}

/// 若创建 Widget Extension Target，请将下方 Bundle 重命名为该 Target 的 @main 入口。
struct AureonWidgetsBundlePreview {
    static var widgets: [any Widget] {
        [AureonWatchlistWidget(), AureonStrategyWidget()]
    }
}
