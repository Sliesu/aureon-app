//
//  InsightCards.swift
//  aureon-app
//
//  建议卡片、宏观卡片、新闻列表、订单簿、审计时间线。
//

import SwiftUI
import Charts

struct AdviceRecordCard: View {
    let record: AdviceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.instId).font(AureonFont.mono(13, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                StatusBadge(text: record.action.labelZh, tint: record.action == .buy ? .buy : (record.action == .sell ? .sell : .hold))
                Spacer()
                Text(AureonFormat.relativeTime(record.createdAt)).font(AureonFont.mono(10)).foregroundStyle(AureonPalette.mutedSlate)
            }
            Text("置信度 \(Int(record.confidencePercent))%").font(AureonFont.mono(11)).foregroundStyle(AureonPalette.gold500)
            if let summary = record.llmSummaryZh {
                Text(summary).font(AureonFont.body(12)).foregroundStyle(AureonPalette.warmWhite.opacity(0.9))
            }
            if !record.riskFlags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(record.riskFlags) { flag in
                        GoldChip(text: flag.labelZh)
                    }
                }
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}

struct MacroOverviewCard: View {
    let macro: MacroSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("加密宏观").aureonKicker()
                Spacer()
                Text("恐慌贪婪指数 \(macro.fearGreedIndex)").font(AureonFont.mono(11)).foregroundStyle(AureonPalette.gold500)
            }
            HStack(spacing: 16) {
                StatChip(label: "总市值", value: AureonFormat.compactUsd(macro.totalMarketCapUsd))
                StatChip(label: "BTC 占比", value: AureonFormat.percent(macro.btcDominancePercent, decimals: 1, showsSign: false))
            }
            Chart(macro.history) { point in
                AreaMark(x: .value("日期", point.t), y: .value("值", point.value))
                    .foregroundStyle(LinearGradient(colors: [AureonPalette.gold500.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("日期", point.t), y: .value("值", point.value))
                    .foregroundStyle(AureonPalette.gold500)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
        .glassCard()
    }
}

struct HeadlinesListView: View {
    let headlines: [HeadlineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(headlines) { headline in
                VStack(alignment: .leading, spacing: 3) {
                    Text(headline.title).font(AureonFont.body(12, weight: .medium)).foregroundStyle(AureonPalette.warmWhite)
                    HStack {
                        Text(headline.source).font(AureonFont.mono(10)).foregroundStyle(AureonPalette.gold500)
                        Text(AureonFormat.relativeTime(headline.publishedAt)).font(AureonFont.mono(10)).foregroundStyle(AureonPalette.mutedSlate)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .glassCard(style: .panel)
    }
}

struct MarketIntelCard: View {
    let intel: MarketIntelSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("市场情报").aureonKicker()
            Text(intel.summaryZh).font(AureonFont.body(12)).foregroundStyle(AureonPalette.warmWhite.opacity(0.92))
            HStack(spacing: 16) {
                StatChip(label: "多空比", value: AureonFormat.price(intel.longShortRatio, decimals: 2))
                StatChip(label: "24h 清算", value: AureonFormat.compactUsd(intel.liquidations24hUsd))
                StatChip(label: "资金费率", value: AureonFormat.percent(intel.fundingRatePercent, decimals: 3))
            }
        }
        .glassCard(style: .panel)
    }
}

struct OrderBookMiniView: View {
    let snapshot: OrderBookSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("订单簿").aureonKicker()
            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 3) {
                    ForEach(snapshot.asks.prefix(5).reversed()) { level in
                        levelRow(level, color: AureonPalette.signalSell)
                    }
                }
                VStack(spacing: 3) {
                    ForEach(snapshot.bids.prefix(5)) { level in
                        levelRow(level, color: AureonPalette.signalBuy)
                    }
                }
            }
        }
        .glassCard(style: .panel)
    }

    private func levelRow(_ level: OrderBookLevel, color: Color) -> some View {
        HStack {
            Text(AureonFormat.price(level.price)).font(AureonFont.mono(10)).foregroundStyle(color)
            Spacer()
            Text(AureonFormat.price(level.size, decimals: 3)).font(AureonFont.mono(10)).foregroundStyle(AureonPalette.mutedSlate)
        }
    }
}

struct AuditTimelineView: View {
    let events: [AuditEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(events) { event in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(AureonPalette.gold500).frame(width: 6, height: 6).padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            GoldChip(text: event.kind.labelZh)
                            Text(AureonFormat.relativeTime(event.occurredAt)).font(AureonFont.mono(10)).foregroundStyle(AureonPalette.mutedSlate)
                        }
                        Text(event.messageZh).font(AureonFont.body(12)).foregroundStyle(AureonPalette.warmWhite.opacity(0.9))
                    }
                }
            }
        }
    }
}
