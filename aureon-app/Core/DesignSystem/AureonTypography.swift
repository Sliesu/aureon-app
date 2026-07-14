//
//  AureonTypography.swift
//  aureon-app
//
//  三层字体体系，对齐 Web 版 Fraunces（展示）/ Newsreader（正文）/ IBM Plex Mono（数据）。
//  原生实现使用 SF Pro 系列的 serif/rounded/monospaced 设计变体以取得同等气质，
//  避免额外打包第三方字体资源。
//

import SwiftUI

enum AureonFont {
    /// 展示字体：Hero 标题、instrument 名称、Vault Section 标题。
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// 正文字体：说明文案、卡片描述。
    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// 数据字体：价格、K 线轴、Kicker 标签。
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Kicker：全大写 + 宽字距标签（移动端字距较 Web 收敛，避免视觉过宽）。
    static func kicker() -> Font { mono(11, weight: .semibold) }
}

extension View {
    func aureonKicker() -> some View {
        self
            .font(AureonFont.kicker())
            .kerning(1.6)
            .textCase(.uppercase)
            .foregroundStyle(AureonPalette.gold500.opacity(0.85))
    }
}
