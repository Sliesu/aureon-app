//
//  TickerHeaderCard.swift
//  aureon-app
//
//  实时报价头卡：last/bid/ask/24h 涨跌 + 连接状态徽章。
//

import SwiftUI

struct TickerHeaderCard: View {
    let instId: String
    let ticker: TickerSnapshot?
    let liveness: ConnectionLiveness
    let isWatched: Bool
    let onToggleWatch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(instId)
                        .font(AureonFont.display(22, weight: .semibold))
                        .foregroundStyle(AureonPalette.goldGradient)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(livenessColor)
                            .frame(width: 6, height: 6)
                        Text(liveness.labelZh)
                            .font(AureonFont.mono(10, weight: .medium))
                            .foregroundStyle(AureonPalette.mutedSlate)
                    }
                }
                Spacer()
                Button(action: onToggleWatch) {
                    Image(systemName: isWatched ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundStyle(isWatched ? AureonPalette.gold500 : AureonPalette.mutedSlate)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isWatched ? "取消自选" : "加入自选")
            }

            if let ticker {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(AureonFormat.price(ticker.last, decimals: 2))
                        .font(AureonFont.mono(30, weight: .semibold))
                        .foregroundStyle(AureonPalette.warmWhite)
                    StatusBadge(
                        text: AureonFormat.percent(ticker.changePercent24h, decimals: 2),
                        tint: ticker.changePercent24h >= 0 ? .buy : .sell
                    )
                }

                HStack(spacing: 18) {
                    StatChip(label: "买一", value: AureonFormat.price(ticker.bid))
                    StatChip(label: "卖一", value: AureonFormat.price(ticker.ask))
                    StatChip(label: "24h 最高", value: AureonFormat.price(ticker.high24h))
                    StatChip(label: "24h 最低", value: AureonFormat.price(ticker.low24h))
                }
            } else {
                LoadingStateView(message: "连接行情中…")
            }
        }
        .glassCard()
    }

    private var livenessColor: Color {
        switch liveness {
        case .live: return AureonPalette.signalBuy
        case .polling: return AureonPalette.gold500
        case .offline: return AureonPalette.signalSell
        }
    }
}
