//
//  WidgetTheme.swift
//  AureonWidgets
//
//  Extension 自身的最小视觉令牌（乌木金纹配色 + 简化格式化），与主 App
//  `Core/DesignSystem/AureonPalette.swift` 保持视觉一致但独立维护，避免
//  为了几个颜色常量把整个 DesignSystem 模块耦合进 Widget Extension。
//

import SwiftUI

enum WidgetPalette {
    static let ebony950 = Color(red: 0.043, green: 0.043, blue: 0.055)
    static let ebony900 = Color(red: 0.071, green: 0.071, blue: 0.086)
    static let gold500 = Color(red: 0.831, green: 0.686, blue: 0.216)
    static let warmWhite = Color(red: 0.941, green: 0.925, blue: 0.894)
    static let mutedSlate = Color(red: 0.612, green: 0.616, blue: 0.647)
    static let signalBuy = Color(red: 0.298, green: 0.686, blue: 0.514)
    static let signalSell = Color(red: 0.827, green: 0.325, blue: 0.325)
}

enum WidgetFormat {
    static func price(_ value: Double) -> String {
        value >= 100 ? String(format: "%.1f", value) : String(format: "%.4f", value)
    }

    static func percent(_ value: Double, decimals: Int = 2) -> String {
        String(format: "%+.\(decimals)f%%", value)
    }

    static func currency(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        return "\(sign)$" + String(format: "%.2f", abs(value))
    }

    static func relativeUpdatedAt(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
