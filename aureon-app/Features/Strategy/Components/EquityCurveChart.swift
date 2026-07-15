//
//  EquityCurveChart.swift
//  aureon-app
//
//  权益折线图 + 交易买卖点标记，对齐 Web 版 BacktestPanel 权益曲线。
//

import SwiftUI
import Charts

struct EquityCurveChart: View {
    let points: [EquityPoint]
    var trades: [TradeRecord] = []

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("时间", point.t), y: .value("权益", point.equity))
                    .foregroundStyle(AureonPalette.gold500)
                    .interpolationMethod(.catmullRom)

                AreaMark(x: .value("时间", point.t), y: .value("权益", point.equity))
                    .foregroundStyle(
                        LinearGradient(colors: [AureonPalette.gold500.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom)
                    )
            }

            ForEach(tradeMarkers, id: \.trade.id) { marker in
                PointMark(x: .value("时间", marker.trade.exitAt), y: .value("权益", marker.equityAtExit))
                    .foregroundStyle(marker.trade.isWin ? AureonPalette.signalBuy : AureonPalette.signalSell)
                    .symbolSize(28)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine().foregroundStyle(AureonPalette.goldRim.opacity(0.08))
                AxisValueLabel().foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(AureonPalette.goldRim.opacity(0.06))
                AxisValueLabel(format: .dateTime.hour().minute()).foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .frame(height: 180)
        .accessibilityLabel("权益曲线")
    }

    /// 交易标记必须落在权益曲线的量纲上，而非成交价格；否则价格（如 6 万美元级）
    /// 会远超权益量纲（如 1 万美元级），导致图表比例完全失真。
    /// 因此按 `exitAt` 就近匹配权益曲线上的点，取其权益值作为标记纵坐标。
    private var tradeMarkers: [(trade: TradeRecord, equityAtExit: Double)] {
        guard !points.isEmpty else { return [] }
        return trades.map { trade in
            let nearest = points.min(by: { abs($0.t.timeIntervalSince(trade.exitAt)) < abs($1.t.timeIntervalSince(trade.exitAt)) })
            return (trade, nearest?.equity ?? points.last?.equity ?? 0)
        }
    }
}
