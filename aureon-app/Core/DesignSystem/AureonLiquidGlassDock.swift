//
//  AureonLiquidGlassDock.swift
//  aureon-app
//
//  底部液态玻璃 Dock：五项一级导航。iOS 26+ 使用原生 GlassEffectContainer +
//  glassEffectID 实现选中项的液态融合过渡；旧版降级为 Material 胶囊 + 金色光晕。
//

import SwiftUI

enum AureonDockMetrics {
    static let barHeight: CGFloat = 58
    static var reservedHeight: CGFloat { barHeight + 28 }
}

struct AureonLiquidGlassDock: View {
    @Binding var selectedTab: AureonTab
    @Environment(AppEnvironment.self) private var env
    @Namespace private var glassNamespace

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 10) {
                    dockRow
                }
            } else {
                dockRow
                    .background(legacyBackground)
            }
        }
        .frame(height: AureonDockMetrics.barHeight)
        .padding(.horizontal, 6)
        .accessibilityElement(children: .contain)
    }

    private var dockRow: some View {
        HStack(spacing: 4) {
            ForEach(AureonTab.allCases) { tab in
                DockItem(
                    tab: tab,
                    isSelected: tab == selectedTab,
                    namespace: glassNamespace
                ) {
                    guard tab != selectedTab else { return }
                    env.haptics.selection()
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
    }

    private var legacyBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(AureonPalette.ebony900.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
    }
}

private struct DockItem: View {
    let tab: AureonTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                Text(tab.titleZh)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .foregroundStyle(isSelected ? AureonPalette.gold100 : AureonPalette.mutedSlate)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .background(itemBackground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.titleZh)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var itemBackground: some View {
        if isSelected {
            if #available(iOS 26.0, *) {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.tint(AureonPalette.gold500.opacity(0.32)), in: .capsule)
                    .glassEffectID(tab.id, in: namespace)
                    .overlay(
                        Capsule().strokeBorder(AureonPalette.gold500.opacity(0.55), lineWidth: 1)
                    )
            } else {
                Capsule()
                    .fill(AureonPalette.gold500.opacity(0.16))
                    .overlay(Capsule().strokeBorder(AureonPalette.gold500.opacity(0.55), lineWidth: 1))
                    .shadow(color: AureonPalette.gold500.opacity(0.35), radius: 10, x: 0, y: 2)
            }
        } else {
            Color.clear
        }
    }
}
