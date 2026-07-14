//
//  SegmentedPills.swift
//  aureon-app
//
//  横向可滚动的胶囊分段控件，对齐 Web 版移动端 pill nav（Settings / Account tabs）。
//

import SwiftUI

struct SegmentedPills<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    let isSelected = item == selection
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            selection = item
                        }
                    } label: {
                        Text(label(item))
                            .font(AureonFont.body(13, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? Color.black : AureonPalette.mutedSlate)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    isSelected
                                        ? AureonPalette.gold500
                                        : Color.white.opacity(0.05)
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollClipDisabled()
    }
}
