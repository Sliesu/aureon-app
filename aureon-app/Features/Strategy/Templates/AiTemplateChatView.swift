//
//  AiTemplateChatView.swift
//  aureon-app
//
//  AI 策略草稿对话：本地演示版 propose/refine，草稿 ID 持久化于 DraftStore。
//

import SwiftUI

struct AiTemplateChatView: View {
    @Binding var draft: StrategyTemplateDraft
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [ChatMessage] = [
        ChatMessage(isUser: false, text: "你好，我是策略助手。告诉我你的目标（例如：稳健定投、追踪趋势），我可以帮你生成或优化模板参数。")
    ]
    @State private var draftText: String = ""
    @State private var isThinking = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                        }
                        if isThinking {
                            LoadingStateView(message: "AI 正在生成建议…")
                        }
                    }
                    .padding(14)
                }
                Divider().overlay(Color.white.opacity(0.06))
                HStack(spacing: 8) {
                    TextField("描述你的策略目标…", text: $draftText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 26))
                    }
                    .disabled(draftText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(12)
            }
            .navigationTitle("AI 策略对话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func send() {
        let text = draftText
        messages.append(ChatMessage(isUser: true, text: text))
        draftText = ""
        isThinking = true
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            applySuggestion(from: text)
            messages.append(ChatMessage(isUser: false, text: "已根据你的描述调整参数：止盈 \(AureonFormat.percent(draft.takeProfitPercent, decimals: 1))，止损 \(AureonFormat.percent(-draft.stopLossPercent, decimals: 1, showsSign: false))，单笔金额 $\(Int(draft.sizingUsd))。（本地演示生成，非真实 LLM 调用）"))
            isThinking = false
        }
    }

    private func applySuggestion(from text: String) {
        if text.contains("稳健") || text.contains("保守") {
            draft.takeProfitPercent = 4
            draft.stopLossPercent = 2
            draft.leverage = 1
        } else if text.contains("激进") || text.contains("趋势") {
            draft.takeProfitPercent = 10
            draft.stopLossPercent = 5
            draft.leverage = min(draft.leverage + 1, 5)
        }
    }
}

private struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            Text(message.text)
                .font(AureonFont.body(13))
                .foregroundStyle(message.isUser ? Color.black : AureonPalette.warmWhite)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(message.isUser ? AureonPalette.gold500.opacity(0.85) : Color.white.opacity(0.06))
                )
            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}
