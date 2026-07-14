//
//  Buttons.swift
//  aureon-app
//
//  金色 CTA 与语义买卖按钮，对齐 Web 版 AdviceBoard CTA / OrderModal 买卖按钮。
//

import SwiftUI

struct GoldCapsuleButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AureonFont.body(14, weight: .semibold))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(
                Capsule().fill(
                    isEnabled
                        ? LinearGradient(colors: [AureonPalette.gold500, AureonPalette.gold700], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                )
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SemanticActionButtonStyle: ButtonStyle {
    let tint: SemanticTint

    func makeBody(configuration: Configuration) -> some View {
        let color = AureonPalette.semanticTint(tint)
        configuration.label
            .font(AureonFont.body(15, weight: .bold))
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [color, color.opacity(0.75)], startPoint: .top, endPoint: .bottom))
            )
            .shadow(color: color.opacity(0.35), radius: 12, x: 0, y: 6)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AureonFont.body(13, weight: .medium))
            .foregroundStyle(AureonPalette.warmWhite)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    .background(Capsule().fill(Color.white.opacity(0.03)))
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
