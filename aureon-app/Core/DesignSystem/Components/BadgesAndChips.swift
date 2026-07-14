//
//  BadgesAndChips.swift
//  aureon-app
//
//  金色胶囊标签、状态徽章与统计 Chip，对齐 .aureon-gradient-chip 语言。
//

import SwiftUI

struct GoldChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AureonFont.mono(10, weight: .semibold))
            .foregroundStyle(AureonPalette.gold100)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [AureonPalette.gold100.opacity(0.08), AureonPalette.gold700.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().strokeBorder(AureonPalette.gold500.opacity(0.35), lineWidth: 1))
            )
    }
}

struct StatusBadge: View {
    let text: String
    let tint: SemanticTint

    var body: some View {
        let color = AureonPalette.semanticTint(tint)
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(AureonFont.mono(11, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.12)))
    }
}

struct StatChip: View {
    let label: String
    let value: String
    var tint: Color = AureonPalette.warmWhite

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(AureonFont.mono(10, weight: .medium))
                .foregroundStyle(AureonPalette.mutedSlate)
            Text(value)
                .font(AureonFont.mono(15, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PlaceholderMetricTag: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flask.fill")
            Text("演示占位数据")
        }
        .font(AureonFont.mono(9, weight: .semibold))
        .foregroundStyle(AureonPalette.signalHold)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }
}
