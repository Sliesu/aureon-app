//
//  GlassSurface.swift
//  aureon-app
//
//  自适应玻璃容器：iOS 26+ 使用系统原生 Liquid Glass（glassEffect）；
//  iOS 18–25 降级为 ultraThinMaterial + 金色描边/内高光，视觉语言保持一致。
//  对齐 Web 版 .vault-frame / .glass-panel 双轨面板体系。
//

import SwiftUI

enum GlassSurfaceStyle {
    case frame   // 对应 .vault-frame：主区块
    case panel   // 对应 .glass-panel：次级面板

    var cornerRadius: CGFloat {
        switch self {
        case .frame: return 22
        case .panel: return 18
        }
    }
}

struct GlassSurface<Content: View>: View {
    var style: GlassSurfaceStyle = .frame
    var showsTopAccent: Bool = true
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(background)
            .overlay(alignment: .top) {
                if showsTopAccent {
                    LinearGradient(
                        colors: [.clear, AureonPalette.gold500.opacity(0.35), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    .padding(.horizontal, style.cornerRadius * 0.6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var background: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .fill(.clear)
                .glassEffect(
                    .regular.tint(AureonPalette.ebony900.opacity(0.35)),
                    in: RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                )
                .overlay(strokeOverlay)
        } else {
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                        .fill(AureonPalette.ebony900.opacity(0.42))
                )
                .overlay(strokeOverlay)
                .shadow(color: .black.opacity(0.45), radius: 28, x: 0, y: 18)
        }
    }

    private var strokeOverlay: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.16), AureonPalette.goldRim.opacity(0.12), Color.white.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

extension View {
    /// 便捷修饰符：将任意内容包裹为标准 Vault 玻璃面板。
    func glassCard(style: GlassSurfaceStyle = .frame, padding: CGFloat = 16) -> some View {
        GlassSurface(style: style) {
            self.padding(padding)
        }
    }
}
