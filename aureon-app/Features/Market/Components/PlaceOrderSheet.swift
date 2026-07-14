//
//  PlaceOrderSheet.swift
//  aureon-app
//
//  模拟下单表单：Face ID/Touch ID 二次确认 + 风控拒绝态展示。
//  对齐 Web 版 OrderModal，明确标注为模拟盘操作。
//

import SwiftUI

struct PlaceOrderSheet: View {
    let instId: String
    let lastPrice: Double?
    let scope: WorkspaceScope
    let riskLimits: RiskLimits
    let isSubmitting: Bool
    let errorMessage: String?
    let onSubmit: (OrderSide, Double, InstrumentType, Double) async -> Void
    let onDismiss: () -> Void

    @Environment(AppEnvironment.self) private var env
    @State private var side: OrderSide = .buy
    @State private var instType: InstrumentType = .spot
    @State private var sizeUsdText: String = "100"
    @State private var leverage: Double = 1

    private var sizeUsd: Double { Double(sizeUsdText) ?? 0 }
    private var exceedsLimit: Bool { sizeUsd > riskLimits.maxOrderNotionalUsd }

    var body: some View {
        NavigationStack {
            Form {
                Section("模拟盘 · 交易对") {
                    HStack {
                        Text(instId).font(AureonFont.mono(15, weight: .semibold))
                        Spacer()
                        if let lastPrice {
                            Text(AureonFormat.price(lastPrice)).foregroundStyle(AureonPalette.mutedSlate)
                        }
                    }
                }

                Section("方向") {
                    Picker("方向", selection: $side) {
                        ForEach(OrderSide.allCases) { Text($0.labelZh).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                if scope.tradingMode == .both {
                    Section("市场") {
                        Picker("市场", selection: $instType) {
                            ForEach(InstrumentType.allCases) { Text($0.labelZh).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("金额（USD）") {
                    TextField("下单金额", text: $sizeUsdText)
                        .keyboardType(.decimalPad)
                    if exceedsLimit {
                        Text("超出单笔上限 \(AureonFormat.currency(riskLimits.maxOrderNotionalUsd))")
                            .font(AureonFont.body(12))
                            .foregroundStyle(AureonPalette.signalSell)
                    }
                }

                if instType == .swap {
                    Section("杠杆") {
                        Stepper(value: $leverage, in: 1...riskLimits.maxLeverage, step: 1) {
                            Text("\(Int(leverage))x")
                        }
                    }
                }

                if scope.automationMode == .suggestOnly {
                    Section {
                        RiskRejectedBanner(reason: .suggestOnlyBlocked)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(AureonFont.body(13))
                            .foregroundStyle(AureonPalette.signalSell)
                    }
                }

                Section {
                    Button {
                        Task { await confirmAndSubmit() }
                    } label: {
                        if isSubmitting {
                            ProgressView().tint(.black)
                        } else {
                            Text("使用 \(env.biometrics.biometryKindLabel) 确认下单")
                        }
                    }
                    .buttonStyle(SemanticActionButtonStyle(tint: side == .buy ? .buy : .sell))
                    .disabled(isSubmitting || sizeUsd <= 0 || exceedsLimit)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("模拟下单")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func confirmAndSubmit() async {
        let outcome = await env.biometrics.authorize(reasonZh: "确认模拟下单 \(instId)")
        switch outcome {
        case .authorized, .unavailable:
            await onSubmit(side, sizeUsd, instType, leverage)
        case .denied:
            env.haptics.warning()
        }
    }
}
