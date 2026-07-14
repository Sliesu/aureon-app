//
//  IntervalPicker.swift
//  aureon-app
//

import SwiftUI

struct IntervalPicker: View {
    @Binding var interval: CandleInterval
    var indicators: Binding<IndicatorToggles>

    var body: some View {
        HStack {
            SegmentedPills(items: CandleInterval.allCases, selection: $interval) { $0.labelZh }
            Spacer()
            Menu {
                Toggle("EMA7", isOn: indicators.showEmaFast)
                Toggle("EMA25", isOn: indicators.showEmaSlow)
                Toggle("RSI", isOn: indicators.showRsi)
                Toggle("成交量", isOn: indicators.showVolume)
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(AureonPalette.gold500)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.05)))
            }
        }
    }
}
