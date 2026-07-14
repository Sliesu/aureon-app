//
//  HapticsManager.swift
//  aureon-app
//
//  统一触感反馈：Dock 切换、下单成功/拒绝、风险告警。
//

import UIKit

@MainActor
final class HapticsManager {
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    func selection() {
        selectionGenerator.selectionChanged()
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}
