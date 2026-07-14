//
//  AureonApp.swift
//  aureon-app
//
//  AUREON — 乌木金纹量化工作台的原生 iOS 入口。
//

import SwiftUI

@main
struct AureonApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .preferredColorScheme(.dark)
                .tint(AureonPalette.gold500)
        }
    }
}
