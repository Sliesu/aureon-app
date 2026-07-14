//
//  SettingsEditors.swift
//  aureon-app
//
//  设置各分区编辑器：产品范围、风控限额、显示偏好、连接状态、关于。
//

import SwiftUI

struct ProductScopeEditor: View {
    @Binding var scope: WorkspaceScope
    let onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("产品范围").aureonKicker()
            Picker("交易模式", selection: $scope.tradingMode) {
                ForEach(TradingMode.allCases) { Text($0.labelZh).tag($0) }
            }
            .onChange(of: scope.tradingMode) { _, _ in onCommit() }

            Picker("自动化模式", selection: $scope.automationMode) {
                ForEach(AutomationMode.allCases) { Text($0.labelZh).tag($0) }
            }
            .onChange(of: scope.automationMode) { _, _ in onCommit() }

            HStack {
                Text("租户模式").font(AureonFont.body(13)).foregroundStyle(AureonPalette.warmWhite)
                Spacer()
                Text(scope.tenantMode.labelZh).font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
            }
        }
        .glassCard()
    }
}

struct RiskLimitsEditor: View {
    @Binding var limits: RiskLimits
    let onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("风控上限").aureonKicker()
            sliderRow(title: "单笔订单上限", value: $limits.maxOrderNotionalUsd, range: 50...5_000, formatter: { AureonFormat.currency($0) })
            sliderRow(title: "日内亏损上限", value: $limits.maxDailyLossUsd, range: 20...2_000, formatter: { AureonFormat.currency($0) })
            sliderRow(title: "持仓名义金额上限", value: $limits.maxPositionNotionalUsd, range: 100...20_000, formatter: { AureonFormat.currency($0) })
            sliderRow(title: "最大杠杆", value: $limits.maxLeverage, range: 1...20, formatter: { "\(Int($0))x" })
            Stepper("最大持仓数量 \(limits.maxOpenPositions)", value: $limits.maxOpenPositions, in: 1...20)
                .font(AureonFont.body(13))
                .foregroundStyle(AureonPalette.warmWhite)
            Button("保存风控设置", action: onCommit).buttonStyle(GoldCapsuleButtonStyle())
        }
        .glassCard()
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, formatter: @escaping (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(AureonFont.body(13)).foregroundStyle(AureonPalette.warmWhite)
                Spacer()
                Text(formatter(value.wrappedValue)).font(AureonFont.mono(12, weight: .semibold)).foregroundStyle(AureonPalette.gold500)
            }
            Slider(value: value, in: range).tint(AureonPalette.gold500)
        }
    }
}

struct DisplayPrefsEditor: View {
    @Binding var prefs: DisplayPreferences
    let onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("显示偏好").aureonKicker()
            Picker("报价币种", selection: $prefs.quoteCurrency) {
                ForEach(QuoteCurrency.allCases) { Text($0.rawValue).tag($0) }
            }
            .onChange(of: prefs.quoteCurrency) { _, _ in onCommit() }
            Stepper("小数位 \(prefs.decimalPlaces)", value: $prefs.decimalPlaces, in: 0...6)
                .onChange(of: prefs.decimalPlaces) { _, _ in onCommit() }
        }
        .glassCard()
    }
}

struct ConnectionStatusCard: View {
    let connectors: RuntimeConnectorSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("连接状态").aureonKicker()
            statusRow(title: "OKX 凭据", isOn: connectors.okxConfigured)
            statusRow(title: "OKX 模拟盘", isOn: connectors.okxSimulated)
            statusRow(title: "LLM 服务", isOn: connectors.llmConfigured)
            statusRow(title: "市场情报聚合", isOn: connectors.marketIntelConfigured)
        }
        .glassCard()
    }

    private func statusRow(title: String, isOn: Bool) -> some View {
        HStack {
            Text(title).font(AureonFont.body(13)).foregroundStyle(AureonPalette.warmWhite)
            Spacer()
            StatusBadge(text: isOn ? "已就绪" : "未配置", tint: isOn ? .buy : .hold)
        }
    }
}

struct DataSourceEditor: View {
    @Environment(AppEnvironment.self) private var env
    @State private var liveURLText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("API 环境").aureonKicker()
            Picker("数据源", selection: Binding(
                get: { env.dataSourceMode },
                set: { newMode in env.switchDataSource(newMode, baseURLString: liveURLText) }
            )) {
                ForEach(DataSourceMode.allCases) { Text($0.displayNameZh).tag($0) }
            }
            if env.dataSourceMode == .live {
                TextField("真实后端 Base URL", text: $liveURLText)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Text("当前仓库尚未实现服务端；填写后仅用于结构化演示 LiveAPIClient 的请求路径。")
                    .font(AureonFont.body(10))
                    .foregroundStyle(AureonPalette.mutedSlate)
            }

            Divider().overlay(Color.white.opacity(0.06))

            Text("演示场景（仅 Mock 模式生效）").font(AureonFont.body(12, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
            Picker("演示场景", selection: Binding(
                get: { env.draftStore.mockScenario },
                set: { env.setMockScenario($0) }
            )) {
                ForEach(MockScenario.allCases) { Text($0.labelZh).tag($0) }
            }
            .disabled(env.dataSourceMode != .mock)
        }
        .glassCard()
    }
}

struct AboutSectionView: View {
    let releaseNotes: [ReleaseNote]
    let appVersion: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("关于 AUREON").aureonKicker()
            Text("当前版本 \(appVersion)").font(AureonFont.body(13)).foregroundStyle(AureonPalette.warmWhite)
            ForEach(releaseNotes) { note in
                VStack(alignment: .leading, spacing: 4) {
                    Text("v\(note.version)").font(AureonFont.mono(12, weight: .semibold)).foregroundStyle(AureonPalette.gold500)
                    ForEach(note.highlightsZh, id: \.self) { highlight in
                        Text("· \(highlight)").font(AureonFont.body(11)).foregroundStyle(AureonPalette.mutedSlate)
                    }
                }
                .padding(.bottom, 4)
            }
            Text("量化策略和 AI 输出不构成投资建议。所有交易与自动化演示均为本地模拟，不会产生真实资金操作。")
                .font(AureonFont.body(10))
                .foregroundStyle(AureonPalette.mutedSlate)
        }
        .glassCard()
    }
}
