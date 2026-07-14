//
//  AureonPalette.swift
//  aureon-app
//
//  乌木金纹色板 — 对齐 Web 版 globals.css 的 --vault-void / --aureon-glow
//  与 tailwind.config.ts 的 ink / signal / accent 语义色，收敛为原生 Token。
//

import SwiftUI

enum AureonPalette {
    // 乌木底色阶（对应 --vault-void / --vault-fog / ink-9xx）
    static let ebony950 = Color(red: 0x03 / 255, green: 0x04 / 255, blue: 0x06 / 255)
    static let ebony900 = Color(red: 0x08 / 255, green: 0x0A / 255, blue: 0x0F / 255)
    static let ebony800 = Color(red: 0x0C / 255, green: 0x10 / 255, blue: 0x17 / 255)
    static let ebony700 = Color(red: 0x12 / 255, green: 0x18 / 255, blue: 0x26 / 255)
    static let ebony600 = Color(red: 0x1A / 255, green: 0x22 / 255, blue: 0x33 / 255)

    // 香槟金渐变三档（对应 aureon-gradient-text: #f7ecd4 → #dfc068 → #b8892a）
    static let gold100 = Color(red: 0xF7 / 255, green: 0xEC / 255, blue: 0xD4 / 255)
    static let gold500 = Color(red: 0xDF / 255, green: 0xC0 / 255, blue: 0x68 / 255)
    static let gold700 = Color(red: 0xB8 / 255, green: 0x89 / 255, blue: 0x2A / 255)
    static let goldRim = Color(red: 212 / 255, green: 175 / 255, blue: 95 / 255)

    // 语义信号色（对应 tailwind signal.buy / signal.sell / signal.hold）
    static let signalBuy = Color(red: 0x3D / 255, green: 0xFF / 255, blue: 0x9D / 255)
    static let signalSell = Color(red: 0xFF / 255, green: 0x5C / 255, blue: 0x7A / 255)
    static let signalHold = Color(red: 0xC9 / 255, green: 0xD1 / 255, blue: 0xE0 / 255)

    static let warmWhite = Color(red: 0xF0 / 255, green: 0xEA / 255, blue: 0xD8 / 255)
    static let mutedSlate = Color(red: 0x94 / 255, green: 0x9C / 255, blue: 0xB0 / 255)

    static let goldGradient = LinearGradient(
        colors: [gold100, gold500, gold700],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let ebonyGradient = LinearGradient(
        colors: [ebony950, ebony900, ebony950],
        startPoint: .top,
        endPoint: .bottom
    )

    static func semanticTint(_ tint: SemanticTint) -> Color {
        switch tint {
        case .buy: return signalBuy
        case .sell: return signalSell
        case .hold: return signalHold
        }
    }
}
