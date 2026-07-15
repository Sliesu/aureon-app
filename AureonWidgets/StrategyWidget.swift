//
//  StrategyWidget.swift
//  AureonWidgets
//
//  桌面小组件：运行中策略摘要（数量 + 最佳已实现盈亏），点击直达运行列表。
//

import AureonShared
import SwiftUI
import WidgetKit

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
            HStack {
                Text("策略运行中")
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(WidgetPalette.gold500)
                Spacer()
                if let snapshot = entry.snapshot {
                    Text(WidgetFormat.relativeUpdatedAt(snapshot.updatedAt))
                        .font(.system(size: 9))
                        .foregroundStyle(WidgetPalette.mutedSlate)
                }
            }

            if let snapshot = entry.snapshot {
                Text("\(snapshot.runningCount) 个运行实例")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetPalette.warmWhite)
                Text(snapshot.topTemplateName)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(WidgetPalette.mutedSlate)
                    .lineLimit(1)
                Text(WidgetFormat.currency(snapshot.topRealizedPnlUsd))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(snapshot.topRealizedPnlUsd >= 0 ? WidgetPalette.signalBuy : WidgetPalette.signalSell)
            } else {
                Spacer(minLength: 0)
                Text("暂无运行中的策略")
                    .font(.system(size: 12))
                    .foregroundStyle(WidgetPalette.mutedSlate)
                Text("打开 AUREON 启动一个策略模板")
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.mutedSlate.opacity(0.8))
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .containerBackground(WidgetPalette.ebony950.gradient, for: .widget)
        .widgetURL(AureonDeepLink.strategyRuns.url)
    }
}

struct AureonStrategyWidget: Widget {
    let kind = AureonWidgetKind.strategy

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StrategyWidgetProvider()) { entry in
            StrategyWidgetView(entry: entry)
        }
        .configurationDisplayName("AUREON 策略摘要")
        .description("展示运行中策略数量与最新已实现盈亏，点击直达运行列表。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
