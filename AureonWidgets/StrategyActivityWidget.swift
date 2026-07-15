//
//  StrategyActivityWidget.swift
//  AureonWidgets
//
//  策略运行 / 回测的 Live Activity：锁屏卡片 + 灵动岛 expanded/compact/minimal
//  三态布局。属性与内容状态定义见 AureonShared.AureonStrategyActivityAttributes，
//  由主 App 的 `LiveActivityManager` 发起/更新/结束。
//

import ActivityKit
import AureonShared
import SwiftUI
import WidgetKit

struct AureonStrategyActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AureonStrategyActivityAttributes.self) { context in
            StrategyActivityLockScreenView(context: context)
                .activityBackgroundTint(WidgetPalette.ebony950)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.templateName)
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundStyle(WidgetPalette.gold500)
                            .lineLimit(1)
                        Text(context.state.statusLabelZh)
                            .font(.system(size: 11))
                            .foregroundStyle(WidgetPalette.mutedSlate)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(WidgetFormat.currency(context.state.realizedPnlUsd))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(context.state.realizedPnlUsd >= 0 ? WidgetPalette.signalBuy : WidgetPalette.signalSell)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: min(max(context.state.progressPercent, 0), 100), total: 100)
                        .tint(WidgetPalette.gold500)
                }
            } compactLeading: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(WidgetPalette.gold500)
            } compactTrailing: {
                Text(WidgetFormat.currency(context.state.realizedPnlUsd))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(context.state.realizedPnlUsd >= 0 ? WidgetPalette.signalBuy : WidgetPalette.signalSell)
            } minimal: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(WidgetPalette.gold500)
            }
            .widgetURL(AureonDeepLink.strategyRuns.url)
        }
    }
}

private struct StrategyActivityLockScreenView: View {
    let context: ActivityViewContext<AureonStrategyActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(context.attributes.templateName)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(WidgetPalette.gold500)
                    .lineLimit(1)
                Spacer()
                Text(context.state.statusLabelZh)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
            }
            ProgressView(value: min(max(context.state.progressPercent, 0), 100), total: 100)
                .tint(WidgetPalette.gold500)
            HStack {
                Text(context.attributes.kind == .backtest ? "回测进度" : "策略运行")
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.mutedSlate)
                Spacer()
                Text(WidgetFormat.currency(context.state.realizedPnlUsd))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(context.state.realizedPnlUsd >= 0 ? WidgetPalette.signalBuy : WidgetPalette.signalSell)
            }
        }
        .padding(14)
    }
}
