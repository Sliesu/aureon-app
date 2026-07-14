//
//  CandleChartView.swift
//  aureon-app
//
//  原生蜡烛图：Swift Charts 组合 RuleMark（高低影线）+ RectangleMark（实体），
//  叠加 EMA 折线、成交量柱与拖拽十字线，对齐 Web 版 TvReplayChart 的核心交互。
//

import SwiftUI
import Charts

struct CandleChartView: View {
    let candles: [Candle]
    let emaFast: [Double]
    let emaSlow: [Double]
    let indicators: IndicatorToggles
    @Binding var selectedCandle: Candle?

    private let minCandleWidth: CGFloat = 7

    private struct SeriesPoint: Identifiable {
        let ts: Date
        let value: Double
        var id: Date { ts }
    }

    private func emaSeries(values: [Double]) -> [SeriesPoint] {
        let aligned = Array(candles.suffix(values.count))
        return zip(aligned, values).map { SeriesPoint(ts: $0.ts, value: $1) }
    }

    var body: some View {
        let contentWidth = max(CGFloat(candles.count) * minCandleWidth, 320)
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 6) {
                priceChart
                    .frame(width: contentWidth, height: 220)
                if indicators.showVolume {
                    volumeChart
                        .frame(width: contentWidth, height: 56)
                }
            }
            .padding(.trailing, 12)
        }
        .defaultScrollAnchor(.trailing)
    }

    private var priceChart: some View {
        Chart {
            ForEach(candles) { candle in
                let isUp = candle.close >= candle.open
                let color = isUp ? AureonPalette.signalBuy : AureonPalette.signalSell

                RuleMark(x: .value("时间", candle.ts), yStart: .value("低", candle.low), yEnd: .value("高", candle.high))
                    .foregroundStyle(color.opacity(0.85))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                RectangleMark(
                    x: .value("时间", candle.ts),
                    yStart: .value("开", candle.open),
                    yEnd: .value("收", candle.close),
                    width: .fixed(minCandleWidth * 0.62)
                )
                .foregroundStyle(color)
            }

            if indicators.showEmaFast {
                ForEach(emaSeries(values: emaFast)) { point in
                    LineMark(x: .value("时间", point.ts), y: .value("EMA7", point.value))
                        .foregroundStyle(AureonPalette.gold500)
                        .lineStyle(StrokeStyle(lineWidth: 1.4))
                }
            }

            if indicators.showEmaSlow {
                ForEach(emaSeries(values: emaSlow)) { point in
                    LineMark(x: .value("时间", point.ts), y: .value("EMA25", point.value))
                        .foregroundStyle(Color.blue.opacity(0.75))
                        .lineStyle(StrokeStyle(lineWidth: 1.2))
                }
            }

            if let selectedCandle {
                RuleMark(x: .value("选中", selectedCandle.ts))
                    .foregroundStyle(AureonPalette.gold500.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
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
        .chartPlotStyle { plot in
            plot.background(Color.white.opacity(0.015))
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let origin = geo[proxy.plotAreaFrame].origin
                                let relativeX = value.location.x - origin.x
                                guard let date: Date = proxy.value(atX: relativeX) else { return }
                                if let closest = candles.min(by: { abs($0.ts.timeIntervalSince(date)) < abs($1.ts.timeIntervalSince(date)) }) {
                                    selectedCandle = closest
                                }
                            }
                    )
            }
        }
        .accessibilityLabel("K 线图")
    }

    private var volumeChart: some View {
        Chart(candles) { candle in
            let isUp = candle.close >= candle.open
            BarMark(x: .value("时间", candle.ts), y: .value("成交量", candle.volume), width: .fixed(minCandleWidth * 0.62))
                .foregroundStyle((isUp ? AureonPalette.signalBuy : AureonPalette.signalSell).opacity(0.35))
        }
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
    }
}
