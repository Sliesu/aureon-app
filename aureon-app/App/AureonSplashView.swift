//
//  AureonSplashView.swift
//  aureon-app
//
//  黑色静态开屏：品牌图保持居中不动，短暂停留后淡入应用主界面。
//

import SwiftUI

struct AureonLaunchContainer: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            RootView()
                .opacity(isShowingSplash ? 0 : 1)
                .accessibilityHidden(isShowingSplash)

            if isShowingSplash {
                AureonSplashView {
                    withAnimation(.easeOut(duration: 0.42)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct AureonSplashView: View {
    let onFinished: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let logoSize = min(
                min(proxy.size.width * 0.70, proxy.size.height * 0.50),
                280
            )

            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image("AureonSplashLogo")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}
