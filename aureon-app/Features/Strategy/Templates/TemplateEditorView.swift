//
//  TemplateEditorView.swift
//  aureon-app
//
//  策略模板编辑器：风格、市场、规则参数、仓位、杠杆、TP/SL、频率、AI 草稿对话入口。
//

import SwiftUI

struct TemplateEditorView: View {
    @Bindable var viewModel: StrategyViewModel
    @State private var showAIChat = false

    var body: some View {
        Form {
            Section("策略风格") {
                StyleGridView(selection: $viewModel.draft.style)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 6)
            }

            Section("基础信息") {
                TextField("模板名称", text: $viewModel.draft.name)
                Picker("市场", selection: $viewModel.draft.instType) {
                    ForEach(InstrumentType.allCases) { Text($0.labelZh).tag($0) }
                }
                TextField("交易对", text: $viewModel.draft.instId)
                    .autocorrectionDisabled()
            }

            Section("频率") {
                Picker("触发方式", selection: $viewModel.draft.frequencyKind) {
                    Text("固定间隔").tag(StrategyFrequencyKind.interval)
                    Text("Cron 表达式").tag(StrategyFrequencyKind.cron)
                }
                .pickerStyle(.segmented)
                if viewModel.draft.frequencyKind == .interval {
                    Stepper("每 \(viewModel.draft.intervalSeconds) 秒", value: $viewModel.draft.intervalSeconds, in: 30...3_600, step: 30)
                }
            }

            Section("仓位与杠杆") {
                Stepper("单笔金额 $\(Int(viewModel.draft.sizingUsd))", value: $viewModel.draft.sizingUsd, in: 10...5_000, step: 10)
                if viewModel.draft.instType == .swap {
                    Stepper("杠杆 \(Int(viewModel.draft.leverage))x", value: $viewModel.draft.leverage, in: 1...20, step: 1)
                }
            }

            Section("风控") {
                Stepper("止盈 \(AureonFormat.percent(viewModel.draft.takeProfitPercent, decimals: 1))", value: $viewModel.draft.takeProfitPercent, in: 1...30, step: 0.5)
                Stepper("止损 \(AureonFormat.percent(-viewModel.draft.stopLossPercent, decimals: 1, showsSign: false))", value: $viewModel.draft.stopLossPercent, in: 1...20, step: 0.5)
            }

            Section {
                Button {
                    showAIChat = true
                } label: {
                    Label("AI 草稿对话（提案 / 优化）", systemImage: "sparkles")
                }
                Button("保存模板") {
                    Task { await viewModel.saveDraft() }
                }
                .buttonStyle(GoldCapsuleButtonStyle())
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showAIChat) {
            AiTemplateChatView(draft: $viewModel.draft)
        }
    }
}
