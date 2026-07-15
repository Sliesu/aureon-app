//
//  WatchlistWidget.swift
//  AureonWidgets
//
//  桌面小组件：自选交易对实时涨跌摘要。数据来自主 App 写入的 App Group
//  共享快照（`AureonShared.WidgetSnapshotStore`），主 App 数据变化后会
//  通过 `WidgetCenter.shared.reloadTimelines(ofKind:)` 请求刷新。
//

import AureonShared
import SwiftUI
import WidgetKit

struct WatchlistWidgetEntry: TimelineEntry {
    let date: Date
    let items: [WatchlistWidgetSnapshot]
}

struct WatchlistWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchlistWidgetEntry {
        WatchlistWidgetEntry(date: .now, items: [
            WatchlistWidgetSnapshot(instId: "BTC-USDT", last: 64_820, changePercent24h: 1.8),
            WatchlistWidgetSnapshot(instId: "ETH-USDT", last: 3_180, changePercent24h: -0.6)
        ])
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
    @Environment(\.widgetFamily) private var family
    let entry: WatchlistWidgetEntry

    private var rowLimit: Int { family == .systemMedium ? 4 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("AUREON 自选")
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(WidgetPalette.gold500)
                Spacer()
                Text(WidgetFormat.relativeUpdatedAt(entry.date))
                    .font(.system(size: 9))
                    .foregroundStyle(WidgetPalette.mutedSlate)
            }

            if entry.items.isEmpty {
                Spacer(minLength: 0)
                Text("暂无自选交易对")
                    .font(.system(size: 12))
                    .foregroundStyle(WidgetPalette.mutedSlate)
                Text("打开 AUREON 添加常用币种")
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.mutedSlate.opacity(0.8))
                Spacer(minLength: 0)
            } else {
                ForEach(entry.items.prefix(rowLimit)) { item in
                    Link(destination: AureonDeepLink.market(instId: item.instId).url) {
                        HStack {
                            Text(item.instId.replacingOccurrences(of: "-USDT", with: ""))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(WidgetPalette.warmWhite)
                            Spacer()
                            Text(WidgetFormat.price(item.last))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(WidgetPalette.mutedSlate)
                            Text(WidgetFormat.percent(item.changePercent24h, decimals: 1))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(item.changePercent24h >= 0 ? WidgetPalette.signalBuy : WidgetPalette.signalSell)
                        }
                    }
                }
            }
        }
        .padding(12)
        .containerBackground(WidgetPalette.ebony950.gradient, for: .widget)
    }
}

struct AureonWatchlistWidget: Widget {
    let kind = AureonWidgetKind.watchlist

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchlistWidgetProvider()) { entry in
            WatchlistWidgetView(entry: entry)
        }
        .configurationDisplayName("AUREON 自选")
        .description("展示自选交易对的实时涨跌摘要，点击某一行直达该交易对行情页。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
