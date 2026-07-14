//
//  CurrencyFormatting.swift
//  aureon-app
//
//  统一金额/百分比格式化，尊重用户显示偏好（报价币种、小数位、脱敏阈值）。
//

import Foundation

enum AureonFormat {
    static func price(_ value: Double, decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
    }

    static func currency(_ value: Double, symbol: String = "$", decimals: Int = 2) -> String {
        "\(symbol)\(price(value, decimals: decimals))"
    }

    static func percent(_ value: Double, decimals: Int = 2, showsSign: Bool = true) -> String {
        let sign = showsSign && value > 0 ? "+" : ""
        return "\(sign)\(price(value, decimals: decimals))%"
    }

    static func compactUsd(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""
        switch absValue {
        case 1_000_000_000_000...:
            return "\(sign)$\(price(absValue / 1_000_000_000_000, decimals: 2))T"
        case 1_000_000_000...:
            return "\(sign)$\(price(absValue / 1_000_000_000, decimals: 2))B"
        case 1_000_000...:
            return "\(sign)$\(price(absValue / 1_000_000, decimals: 2))M"
        case 1_000...:
            return "\(sign)$\(price(absValue / 1_000, decimals: 1))K"
        default:
            return "\(sign)$\(price(absValue, decimals: 2))"
        }
    }

    static func relativeTime(_ date: Date, referenceDate: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: referenceDate)
    }

    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    static func dateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
