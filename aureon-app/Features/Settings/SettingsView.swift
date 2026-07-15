//
//  SettingsView.swift
//  aureon-app
//
//  我的域主视图：产品范围、风控、显示偏好、连接状态、API 环境、语言、关于。
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: SettingsViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let viewModel {
                    content(viewModel: viewModel)
                } else {
                    LoadingStateView()
                }
            }
            .refreshable { await viewModel?.loadAll() }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if viewModel == nil {
                let vm = SettingsViewModel(repository: env.repository)
                viewModel = vm
                await vm.loadAll()
            }
        }
        .accessibilityIdentifier("settings.root")
    }

    @ViewBuilder
    private func content(viewModel: SettingsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(kicker: "AUREON VAULT", title: "我的", subtitle: "产品模式、风控配置与连接状态。")
                .padding(.horizontal, 16)
                .padding(.top, 8)

            languageCard.padding(.horizontal, 16)

            switch viewModel.payload {
            case .idle, .loading:
                LoadingStateView()
            case .failed(let message):
                ErrorStateView(message: message, onRetry: { Task { await viewModel.loadAll() } })
            case .empty:
                EmptyStateView(title: "暂无设置数据", message: "")
            case .loaded(let payload):
                ProductScopeEditor(
                    scope: Binding(get: { payload.scope }, set: { newValue in
                        env.applyScope(newValue)
                        Task { await viewModel.updateScope(newValue) }
                    }),
                    onCommit: {}
                ).padding(.horizontal, 16)

                RiskLimitsEditor(
                    limits: Bindable(viewModel).editableRiskLimits,
                    onCommit: {
                        Task { await viewModel.commitRiskLimits() }
                    }
                ).padding(.horizontal, 16)

                DisplayPrefsEditor(
                    prefs: Bindable(viewModel).editableDisplayPrefs,
                    onCommit: {
                        Task { await viewModel.commitDisplayPrefs() }
                        env.applyDisplayPrefs(viewModel.editableDisplayPrefs)
                    }
                ).padding(.horizontal, 16)

                NotificationStatusCard(notifications: env.notifications).padding(.horizontal, 16)

                ConnectionStatusCard(connectors: payload.runtimeConnectors).padding(.horizontal, 16)

                DataSourceEditor().padding(.horizontal, 16)

                AboutSectionView(releaseNotes: viewModel.releaseNotes.value ?? [], appVersion: payload.appVersion)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 24)
    }

    private var languageCard: some View {
        HStack {
            Text("语言").font(AureonFont.body(13, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
            Spacer()
            Picker("语言", selection: Binding(get: { env.locale }, set: { env.applyLocale($0) })) {
                ForEach(AppLocale.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .glassCard(style: .panel)
    }
}
