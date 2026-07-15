//
//  StrategyView.swift
//  aureon-app
//
//  策略工作台自适应壳层：总览优先。iPhone（紧凑宽度）用 NavigationStack 逐级导航，
//  iPad（常规宽度）用 NavigationSplitView 侧栏分栏。总览聚合运行 KPI、活跃策略、
//  最近回测与模板快捷入口，其余入口（模板库 / 策略回测 / 运行中心 / AI Pilot）
//  均从总览或侧栏进入，替代此前的两层 segmented + 单一超长 ScrollView。
//

import SwiftUI

/// 策略工作台的一级入口，驱动 iPad 侧栏与 iPhone 逐级导航的目的地。
enum StrategyWorkbenchSection: String, CaseIterable, Identifiable, Hashable {
    case overview
    case templates
    case backtest
    case runs
    case pilot

    var id: String { rawValue }

    var titleZh: String {
        switch self {
        case .overview: return "总览"
        case .templates: return "模板库"
        case .backtest: return "策略回测"
        case .runs: return "运行中心"
        case .pilot: return "AI Pilot"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .templates: return "list.bullet.rectangle.portrait"
        case .backtest: return "chart.xyaxis.line"
        case .runs: return "bolt.horizontal.circle"
        case .pilot: return "sparkles"
        }
    }
}

struct StrategyView: View {
    @Binding var route: StrategyRoute
    @Environment(AppEnvironment.self) private var env
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var strategyViewModel: StrategyViewModel?
    @State private var pilotViewModel: PilotViewModel?
    @State private var selectedSection: StrategyWorkbenchSection = .overview
    @State private var iPhonePath = NavigationPath()
    @State private var iPadDetailPath = NavigationPath()

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if let strategyViewModel, let pilotViewModel {
                if isRegularWidth {
                    ipadLayout(strategyViewModel: strategyViewModel, pilotViewModel: pilotViewModel)
                } else {
                    iphoneLayout(strategyViewModel: strategyViewModel, pilotViewModel: pilotViewModel)
                }
            } else {
                NavigationStack {
                    LoadingStateView().navigationTitle("策略").navigationBarTitleDisplayMode(.inline)
                }
            }
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

    /// 处理来自快捷操作 / Widget / 通知点击的深链请求（运行中心 / 新建模板）。
    private func apply(_ requestedSection: StrategyRoute.Section?) {
        guard let requestedSection else { return }
        switch requestedSection {
        case .runs:
            navigate(to: .runs)
        case .newTemplate:
            strategyViewModel?.beginNewDraft(style: .balanced)
            navigate(to: .templates)
        }
        route.requestedSection = nil
    }

    private func navigate(to section: StrategyWorkbenchSection) {
        if isRegularWidth {
            selectedSection = section
            iPadDetailPath = NavigationPath()
        } else {
            iPhonePath = NavigationPath()
            if section != .overview { iPhonePath.append(section) }
        }
    }

    /// 从任意区域（如总览的模板预览卡片）直接打开某个模板的详情页，
    /// 不经过「先跳模板库列表、再异步消费待打开 id」的两段式导航，
    /// 避免双重 push 的时序竞态导致点击「看起来没有反应」。
    private func openTemplateDetail(_ template: StrategyTemplate) {
        let target = TemplateDetailTarget(id: template.id)
        if isRegularWidth {
            selectedSection = .templates
            iPadDetailPath = NavigationPath()
            iPadDetailPath.append(target)
        } else {
            iPhonePath = NavigationPath()
            iPhonePath.append(target)
        }
    }

    // MARK: - iPad：侧栏分栏

    private func ipadLayout(strategyViewModel: StrategyViewModel, pilotViewModel: PilotViewModel) -> some View {
        NavigationSplitView {
            List {
                ForEach(StrategyWorkbenchSection.allCases) { section in
                    Button {
                        selectedSection = section
                        iPadDetailPath = NavigationPath()
                    } label: {
                        HStack {
                            Label(section.titleZh, systemImage: section.systemImage)
                                .foregroundStyle(selectedSection == section ? AureonPalette.gold500 : AureonPalette.warmWhite)
                            Spacer()
                            if selectedSection == section {
                                Image(systemName: "checkmark").foregroundStyle(AureonPalette.gold500)
                            }
                        }
                    }
                    .listRowBackground(selectedSection == section ? AureonPalette.gold500.opacity(0.1) : Color.clear)
                }
            }
            .navigationTitle("策略工作台")
        } detail: {
            NavigationStack(path: $iPadDetailPath) {
                sectionContent(selectedSection, strategyViewModel: strategyViewModel, pilotViewModel: pilotViewModel)
                    .navigationTitle(selectedSection.titleZh)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: TemplateDetailTarget.self) { target in
                        TemplateDetailView(viewModel: strategyViewModel, templateId: target.id, onRunStarted: { navigate(to: .runs) })
                    }
            }
        }
    }

    // MARK: - iPhone：逐级导航

    private func iphoneLayout(strategyViewModel: StrategyViewModel, pilotViewModel: PilotViewModel) -> some View {
        NavigationStack(path: $iPhonePath) {
            sectionContent(.overview, strategyViewModel: strategyViewModel, pilotViewModel: pilotViewModel)
                .navigationTitle("策略工作台")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: StrategyWorkbenchSection.self) { section in
                    sectionContent(section, strategyViewModel: strategyViewModel, pilotViewModel: pilotViewModel)
                        .navigationTitle(section.titleZh)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .navigationDestination(for: TemplateDetailTarget.self) { target in
                    TemplateDetailView(viewModel: strategyViewModel, templateId: target.id, onRunStarted: { navigate(to: .runs) })
                }
        }
    }

    @ViewBuilder
    private func sectionContent(_ section: StrategyWorkbenchSection, strategyViewModel: StrategyViewModel, pilotViewModel: PilotViewModel) -> some View {
        switch section {
        case .overview:
            StrategyOverviewView(viewModel: strategyViewModel, onNavigate: navigate, onOpenTemplateDetail: openTemplateDetail)
        case .templates:
            TemplatesWorkspaceView(viewModel: strategyViewModel, onRunStarted: { navigate(to: .runs) })
                .padding(16)
        case .backtest:
            ScrollView { BacktestView(viewModel: strategyViewModel).padding(16) }
        case .runs:
            ScrollView { RunListView(viewModel: strategyViewModel).padding(16) }
        case .pilot:
            ScrollView { PilotView(viewModel: pilotViewModel).padding(16) }
        }
    }
}
