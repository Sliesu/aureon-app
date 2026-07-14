//
//  AureonBackground.swift
//  aureon-app
//
//  全局乌木金纹背景：多层径向金色光晕 + 线性乌木渐变 + 程序化低对比木纹。
//  完全使用 SwiftUI Canvas 绘制，无需打包任何纹理图片资源。
//

import SwiftUI

struct AureonBackground: View {
    var body: some View {
        ZStack {
            AureonPalette.ebonyGradient
                .ignoresSafeArea()

            RadialGradient(
                colors: [AureonPalette.goldRim.opacity(0.14), .clear],
                center: UnitPoint(x: 0.08, y: -0.05),
                startRadius: 4,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [AureonPalette.gold500.opacity(0.06), .clear],
                center: UnitPoint(x: 0.95, y: 0.05),
                startRadius: 4,
                endRadius: 360
            )
            .ignoresSafeArea()

            WoodGrainTexture()
                .opacity(0.10)
                .blendMode(.overlay)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

/// 程序化乌木纹理：低对比水平纤维线 + 轻微抖动，避免依赖位图资源或噪点滤镜。
private struct WoodGrainTexture: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x9E3779B9
            func nextRandom() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 40) / Double(1 << 24)
            }

            let rowCount = Int(size.height / 5)
            for row in 0..<max(rowCount, 1) {
                let baseY = CGFloat(row) * 5 + CGFloat(nextRandom() * 3)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: baseY))
                var x: CGFloat = 0
                while x < size.width {
                    let step = CGFloat(18 + nextRandom() * 26)
                    let jitter = CGFloat((nextRandom() - 0.5) * 4)
                    x += step
                    path.addLine(to: CGPoint(x: min(x, size.width), y: baseY + jitter))
                }
                let opacity = 0.5 + nextRandom() * 0.5
                context.stroke(
                    path,
                    with: .color(AureonPalette.gold700.opacity(0.18 * opacity)),
                    lineWidth: 0.6
                )
            }
        }
    }
}
