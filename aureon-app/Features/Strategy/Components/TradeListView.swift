//
//  TradeListView.swift
//  aureon-app
//

import SwiftUI

struct TradeListView: View {
    let trades: [TradeRecord]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(trades.prefix(30)) { trade in
                HStack {
                    StatusBadge(text: trade.side.labelZh, tint: trade.side == .buy ? .buy : .sell)
                    Text("\(AureonFormat.price(trade.entryPrice)) → \(AureonFormat.price(trade.exitPrice))")
                        .font(AureonFont.mono(12))
                        .foregroundStyle(AureonPalette.warmWhite)
                    Spacer()
                    Text(AureonFormat.percent(trade.pnlPercent, decimals: 2))
                        .font(AureonFont.mono(12, weight: .semibold))
                        .foregroundStyle(trade.isWin ? AureonPalette.signalBuy : AureonPalette.signalSell)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
            }
        }
    }
}
