//
//  StateViews.swift
//  aureon-app
//
//  统一的 loading / empty / error 状态视图，覆盖离线、风控拒绝等场景。
//

import SwiftUI

struct LoadingStateView: View {
    var message: String = "加载中…"

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AureonPalette.gold500)
            Text(message)
                .font(AureonFont.body(13))
                .foregroundStyle(AureonPalette.mutedSlate)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView: View {
    var glyph: String = "moon.stars"
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .strokeBorder(AureonPalette.goldRim.opacity(0.4), lineWidth: 1)
                    .frame(width: 52, height: 52)
                Image(systemName: glyph)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AureonPalette.gold500)
            }
            Text(title)
                .font(AureonFont.display(17, weight: .semibold))
                .foregroundStyle(AureonPalette.warmWhite)
            Text(message)
                .font(AureonFont.body(13))
                .foregroundStyle(AureonPalette.mutedSlate)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct ErrorStateView: View {
    var title: String = "加载失败"
    var message: String
    var retryTitle: String = "重试"
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundStyle(AureonPalette.signalSell)
            Text(title)
                .font(AureonFont.display(16, weight: .semibold))
                .foregroundStyle(AureonPalette.warmWhite)
            Text(message)
                .font(AureonFont.body(13))
                .foregroundStyle(AureonPalette.mutedSlate)
                .multilineTextAlignment(.center)
            if let onRetry {
                Button(retryTitle, action: onRetry)
                    .buttonStyle(GoldCapsuleButtonStyle())
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(AureonPalette.signalSell)
            Text("连接已中断，正在使用最近缓存的数据")
                .font(AureonFont.body(12, weight: .medium))
                .foregroundStyle(AureonPalette.warmWhite)
            Spacer()
        }
        .padding(10)
        .glassCard(style: .panel, padding: 0)
    }
}

struct RiskRejectedBanner: View {
    let reason: RiskRejectionReason

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.slash.fill")
                .foregroundStyle(AureonPalette.signalSell)
            Text(reason.messageZh)
                .font(AureonFont.body(12, weight: .medium))
                .foregroundStyle(AureonPalette.warmWhite)
            Spacer()
        }
        .padding(10)
        .glassCard(style: .panel, padding: 0)
    }
}
