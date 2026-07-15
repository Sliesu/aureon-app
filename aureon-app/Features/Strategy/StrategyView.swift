//
//  StrategyView.swift
//  aureon-app
//
//  策略域主视图：顶部「模板 | Pilot」分段，模板内再分「编辑 / 回测 / 运行」。
//  对齐 Web 版 StrategyConsole 双 Tab 结构。
//

import SwiftUI

private enum StrategySection: String, CaseIterable, Hashable {
    case templates = "模板"
    case pilot = "AI Pilot"
}

private enum TemplateSubTab: String, CaseIterable, Hashable {
    case editor = "编辑"
    case backtest = "回测"
    case runs = "运行"
}

struct StrategyView: View {
    @Binding var route: StrategyRoute
    @Environment(AppEnvironment.self) private var env
    @State private var strategyViewModel: StrategyViewModel?
    @State private var pilotViewModel: PilotViewModel?
    @State private var section: StrategySection = .templates
    @State private var templateSubTab: TemplateSubTab = .editor

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(kicker: "AUREON VAULT", title: "策略工作台", subtitle: "模板研发、回测验证与 AI 自主巡航，均为本地演示。")
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    Picker("功能域", selection: $section) {
                        ForEach(StrategySection.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    if env.workspaceScope.tradingMode == .spot {
                        Text("当前为仅现货模式，部分衍生品策略能力将受限。")
                            .font(AureonFont.body(11))
                            .foregroundStyle(AureonPalette.signalHold)
                            .padding(.horizontal, 16)
                    }

                    switch section {
                    case .templates:
                        templatesSection
                    case .pilot:
                        if let pilotViewModel {
                            PilotView(viewModel: pilotViewModel)
                                .padding(.horizontal, 16)
                        } else {
                            LoadingStateView()
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("策略")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if strategyViewModel == nil {
                let vm = StrategyViewModel(repository: env.repository, notifications: env.notifications, haptics: env.haptics, liveActivity: env.liveActivity)
                strategyViewModel = vm
                await vm.loadAll()
            }
            if pilotViewModel == nil {
                let vm = PilotViewModel(repository: env.repository, haptics: env.haptics)
                pilotViewModel = vm
                await vm.loadAll()
            }
        }
        .accessibilityIdentifier("strategy.root")
        .onChange(of: route.requestedSection) { _, newValue in
            apply(newValue)
        }
        .onAppear {
            apply(route.requestedSection)
        }
    }

    /// 处理来自快捷操作 / Widget / 通知点击的深链请求（运行列表 / 新建模板）。
    private func apply(_ requestedSection: StrategyRoute.Section?) {
        guard let requestedSection else { return }
        section = .templates
        switch requestedSection {
        case .runs:
            templateSubTab = .runs
        case .newTemplate:
            templateSubTab = .editor
            strategyViewModel?.beginNewDraft(style: .balanced)
        }
        route.requestedSection = nil
    }

    @ViewBuilder
    private var templatesSection: some View {
        if let strategyViewModel {
            Picker("模板功能", selection: $templateSubTab) {
                ForEach(TemplateSubTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            switch templateSubTab {
            case .editor:
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("已有模板").aureonKicker()
                        Spacer()
                        Button("新建模板") { strategyViewModel.beginNewDraft(style: .balanced) }
                            .buttonStyle(GhostButtonStyle())
                    }
                    TemplateListView(
                        viewModel: strategyViewModel,
                        onEdit: { strategyViewModel.editTemplate($0) },
                        onStart: { template in
                            Task { await strategyViewModel.startRun(templateId: template.id) }
                        }
                    )
                    Divider().overlay(Color.white.opacity(0.06))
                    Text("模板编辑器").aureonKicker()
                    TemplateEditorView(viewModel: strategyViewModel)
                        .frame(minHeight: 480)
                }
                .padding(.horizontal, 16)
            case .backtest:
                BacktestView(viewModel: strategyViewModel)
                    .padding(.horizontal, 16)
            case .runs:
                RunListView(viewModel: strategyViewModel)
                    .padding(.horizontal, 16)
            }
        } else {
            LoadingStateView()
        }
    }
}
