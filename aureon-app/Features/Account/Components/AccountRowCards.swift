//
//  AccountRowCards.swift
//  aureon-app
//
//  账户各类记录的移动端卡片化展示，替代 Web 版宽表（宽表在手机上不可用）。
//

import SwiftUI

struct BalanceRowCard: View {
    let detail: BalanceDetail

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(detail.ccy).font(AureonFont.mono(15, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                Text("冻结 \(AureonFormat.price(detail.frozenBalance, decimals: 4))").font(AureonFont.body(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(AureonFormat.price(detail.availableBalance, decimals: 4)).font(AureonFont.mono(14, weight: .medium)).foregroundStyle(AureonPalette.warmWhite)
                Text(AureonFormat.currency(detail.equityUsd)).font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}

struct PositionRowCard: View {
    let position: Position

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(position.instId).font(AureonFont.mono(14, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                StatusBadge(text: position.side.labelZh, tint: position.side == .long ? .buy : .sell)
                Spacer()
                Text("\(Int(position.leverage))x").font(AureonFont.mono(11)).foregroundStyle(AureonPalette.gold500)
            }
            HStack(spacing: 16) {
                StatChip(label: "数量", value: AureonFormat.price(position.quantity, decimals: 3))
                StatChip(label: "开仓价", value: AureonFormat.price(position.entryPrice))
                StatChip(label: "标记价", value: AureonFormat.price(position.markPrice))
                StatChip(
                    label: "未实现盈亏",
                    value: AureonFormat.currency(position.unrealizedPnlUsd),
                    tint: position.unrealizedPnlUsd >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell
                )
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}

struct PendingOrderRowCard: View {
    let order: PendingOrder

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(order.instId).font(AureonFont.mono(13, weight: .semibold))
                    StatusBadge(text: order.side.labelZh, tint: order.side == .buy ? .buy : .sell)
                }
                Text(AureonFormat.relativeTime(order.createdAt)).font(AureonFont.body(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(AureonFormat.price(order.price)).font(AureonFont.mono(13, weight: .medium))
                Text("\(AureonFormat.price(order.filledSize, decimals: 3))/\(AureonFormat.price(order.size, decimals: 3))")
                    .font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}

struct OrderRowCard: View {
    let order: OrderRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(order.instId).font(AureonFont.mono(13, weight: .semibold))
                    StatusBadge(text: order.side.labelZh, tint: order.side == .buy ? .buy : .sell)
                }
                Text(order.state.labelZh).font(AureonFont.body(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(AureonFormat.price(order.price)).font(AureonFont.mono(13, weight: .medium))
                Text(AureonFormat.relativeTime(order.createdAt)).font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}

struct FillRowCard: View {
    let fill: FillRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(fill.instId).font(AureonFont.mono(13, weight: .semibold))
                    StatusBadge(text: fill.side.labelZh, tint: fill.side == .buy ? .buy : .sell)
                }
                Text("手续费 \(AureonFormat.currency(fill.feeUsd))").font(AureonFont.body(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(AureonFormat.price(fill.price)).font(AureonFont.mono(13, weight: .medium))
                Text(AureonFormat.relativeTime(fill.filledAt)).font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}

struct BillRowCard: View {
    let bill: BillRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(bill.type.labelZh).font(AureonFont.body(13, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                Text(AureonFormat.relativeTime(bill.occurredAt)).font(AureonFont.body(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(AureonFormat.currency(bill.amount))
                    .font(AureonFont.mono(13, weight: .medium))
                    .foregroundStyle(bill.amount >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                Text("余额 \(AureonFormat.price(bill.balanceAfter))").font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}
