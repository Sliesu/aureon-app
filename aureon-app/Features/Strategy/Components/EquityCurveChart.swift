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

            ForEach(trades) { trade in
                PointMark(x: .value("时间", trade.exitAt), y: .value("盈亏", trade.exitPrice))
                    .foregroundStyle(trade.isWin ? AureonPalette.signalBuy : AureonPalette.signalSell)
                    .symbolSize(28)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine().foregroundStyle(AureonPalette.goldRim.opacity(0.08))
                AxisValueLabel().foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .chartXAxis(.hidden)
        .frame(height: 180)
        .accessibilityLabel("权益曲线")
    }
}
