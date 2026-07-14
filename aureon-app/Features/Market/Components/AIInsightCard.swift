//
//  AIInsightCard.swift
//  aureon-app
//
//  AI K 线摘要卡片，对齐 Web 版 /api/ai/candles-analyze 的按需触发体验。
//

import SwiftUI

struct AIInsightCard: View {
    let state: LoadState<String>
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("AI K 线解读", systemImage: "sparkles")
                    .font(AureonFont.body(14, weight: .semibold))
                    .foregroundStyle(AureonPalette.gold500)
                Spacer()
                Button("重新生成", action: onRequest)
                    .buttonStyle(GhostButtonStyle())
                    .disabled(state.isLoading)
            }

            switch state {
            case .idle:
                Button("生成本轮解读", action: onRequest)
                    .buttonStyle(GoldCapsuleButtonStyle())
            case .loading:
                LoadingStateView(message: "AI 正在解读行情…")
            case .loaded(let text):
                Text(text)
                    .font(AureonFont.body(13))
                    .foregroundStyle(AureonPalette.warmWhite.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            case .empty:
                EmptyStateView(title: "暂无解读", message: "点击生成以获取本轮 AI 摘要。")
            case .failed(let message):
                ErrorStateView(message: message, onRetry: onRequest)
            }
        }
        .glassCard(style: .panel)
    }
}
