//
//  AureonApp.swift
//  aureon-app
//
//  AUREON — 乌木金纹量化工作台的原生 iOS 入口。
//

import SwiftUI
import UIKit

@main
struct AureonApp: App {
    @State private var environment = AppEnvironment()

    init() {
        AureonTabBarAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .preferredColorScheme(.dark)
                .tint(AureonPalette.gold500)
        }
    }
}

private enum AureonTabBarAppearance {
    static func configure() {
        let selectedTint = UIColor(red: 0xC0 / 255, green: 0x93 / 255, blue: 0x37 / 255, alpha: 1)
        let selectionBackground = UIColor(red: 0x5A / 255, green: 0x5A / 255, blue: 0x5F / 255, alpha: 1)
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.selectionIndicatorTintColor = selectionBackground

        configure(appearance.stackedLayoutAppearance, selectedTint: selectedTint)
        configure(appearance.inlineLayoutAppearance, selectedTint: selectedTint)
        configure(appearance.compactInlineLayoutAppearance, selectedTint: selectedTint)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = selectedTint
    }

    private static func configure(_ appearance: UITabBarItemAppearance, selectedTint: UIColor) {
        appearance.selected.iconColor = selectedTint
        appearance.selected.titleTextAttributes = [.foregroundColor: selectedTint]
    }
}
