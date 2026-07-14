//
//  StyleGridView.swift
//  aureon-app
//
//  11 种策略风格网格选择器，对齐 Web 版 Rule Lab 分组。
//

import SwiftUI

struct StyleGridView: View {
    @Binding var selection: StrategyStyle

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(StrategyStyle.allCases) { style in
                let isSelected = style == selection
                Button {
                    selection = style
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: style.accentGlyph)
                                .foregroundStyle(isSelected ? AureonPalette.gold500 : AureonPalette.mutedSlate)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(AureonPalette.gold500)
                            }
                        }
                        Text(style.titleZh)
                            .font(AureonFont.body(13, weight: .semibold))
                            .foregroundStyle(AureonPalette.warmWhite)
                        Text(style.descriptionZh)
                            .font(AureonFont.body(10))
                            .foregroundStyle(AureonPalette.mutedSlate)
                            .lineLimit(2)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isSelected ? AureonPalette.gold500.opacity(0.1) : Color.white.opacity(0.03))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(isSelected ? AureonPalette.gold500.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
