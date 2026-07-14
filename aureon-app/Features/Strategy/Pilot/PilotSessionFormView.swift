//
//  PilotSessionFormView.swift
//  aureon-app
//
//  新建 Pilot 会话：启用自动执行前要求 Face ID / Touch ID 确认。
//

import SwiftUI

struct PilotSessionFormView: View {
    @Bindable var viewModel: PilotViewModel
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("基础信息") {
                    TextField("会话名称", text: $viewModel.draftName)
                    TextField("交易对", text: $viewModel.draftInstId)
                }
                Section("决策节流") {
                    Stepper("每 \(viewModel.draftDecisionGapSeconds / 60) 分钟", value: $viewModel.draftDecisionGapSeconds, in: 60...3_600, step: 60)
                }
                Section {
                    Toggle("启用自动执行", isOn: $viewModel.draftAutoExecute)
                    if viewModel.draftAutoExecute {
                        Text("启用后 AI 将在满足条件时自动下单，创建会话前需要 \(env.biometrics.biometryKindLabel) 确认。")
                            .font(AureonFont.body(11))
                            .foregroundStyle(AureonPalette.signalSell)
                    }
                }
                Section {
                    Button("创建会话") {
                        Task {
                            await viewModel.createSession {
                                let outcome = await env.biometrics.authorize(reasonZh: "启用 AI Pilot 自动执行")
                                return outcome == .authorized || outcome == .unavailable
                            }
                            dismiss()
                        }
                    }
                    .buttonStyle(GoldCapsuleButtonStyle())
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("新建 Pilot 会话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
