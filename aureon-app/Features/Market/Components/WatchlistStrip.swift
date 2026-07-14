//
//  WatchlistStrip.swift
//  aureon-app
//
//  自选横向条：对齐 Web 版波动跑马灯 + 自选切换体验。
//

import SwiftUI

struct WatchlistStrip: View {
    let items: [String]
    let selectedInstId: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { instId in
                    let isSelected = instId == selectedInstId
                    let ticker = MockMarketFactory.ticker(instId: instId)
                    Button {
                        onSelect(instId)
                    } label: {
                        HStack(spacing: 6) {
                            Text(instId.replacingOccurrences(of: "-USDT", with: ""))
                                .font(AureonFont.mono(12, weight: .semibold))
                            Text(AureonFormat.percent(ticker.changePercent24h, decimals: 1))
                                .font(AureonFont.mono(11, weight: .medium))
                                .foregroundStyle(ticker.changePercent24h >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                        }
                        .foregroundStyle(isSelected ? AureonPalette.gold100 : AureonPalette.warmWhite)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(isSelected ? AureonPalette.gold500.opacity(0.16) : Color.white.opacity(0.04))
                                .overlay(Capsule().strokeBorder(isSelected ? AureonPalette.gold500.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
