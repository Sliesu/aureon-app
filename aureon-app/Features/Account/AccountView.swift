//
//  AccountView.swift
//  aureon-app
//
//  账户域主视图：资产摘要、持仓、委托、成交、流水，六个子 Tab 使用横向胶囊分段。
//  在 iPad 上使用双栏（Tab 列表 + 内容），手机上宽表已改为可展开卡片。
//

import SwiftUI

struct AccountView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel: AccountViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let viewModel {
                    content(viewModel: viewModel)
                } else {
                    LoadingStateView()
                }
            }
            .refreshable { await viewModel?.loadCurrentTab() }
            .navigationTitle("账户")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if viewModel == nil {
                let vm = AccountViewModel(repository: env.repository)
                viewModel = vm
                await vm.loadCurrentTab()
            }
        }
        .accessibilityIdentifier("account.root")
    }

    @ViewBuilder
    private func content(viewModel: AccountViewModel) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(kicker: "AUREON VAULT", title: "账户工作台", subtitle: "只读展示 OKX 账户数据（当前为本地演示）。")
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if let summary = viewModel.summary {
                summaryCard(summary: summary).padding(.horizontal, 16)
            }

            SegmentedPills(items: viewModel.availableTabs(scope: env.workspaceScope), selection: Bindable(viewModel).selectedTab) { $0.titleZh }
                .padding(.horizontal, 16)
                .onChange(of: viewModel.selectedTab) { _, _ in
                    Task { await viewModel.loadCurrentTab() }
                }

            if viewModel.selectedTab != .assets {
                SegmentedPills(items: InstrumentType.allCases, selection: Bindable(viewModel).instTypeFilter) { $0.labelZh }
                    .padding(.horizontal, 16)
                    .onChange(of: viewModel.instTypeFilter) { _, _ in
                        Task { await viewModel.loadCurrentTab() }
                    }
            }

            tabContent(viewModel: viewModel)
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }

    private func summaryCard(summary: AccountSummary) -> some View {
        HStack(spacing: 18) {
            StatChip(label: "总权益", value: AureonFormat.currency(summary.totalEquityUsd))
            StatChip(label: "可用", value: AureonFormat.currency(summary.totalAvailableUsd))
            StatChip(
                label: "未实现盈亏",
                value: AureonFormat.currency(summary.unrealizedPnlUsd),
                tint: summary.unrealizedPnlUsd >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell
            )
        }
        .glassCard()
    }

    @ViewBuilder
    private func tabContent(viewModel: AccountViewModel) -> some View {
        switch viewModel.selectedTab {
        case .assets:
            stateList(viewModel.balances, empty: ("暂无资产", "该账户当前没有余额记录。")) { detail in
                BalanceRowCard(detail: detail)
            }
        case .positions:
            stateList(viewModel.positions, empty: ("暂无持仓", "当前没有衍生品持仓。")) { position in
                PositionRowCard(position: position)
            }
        case .pending:
            stateList(viewModel.pendingOrders, empty: ("暂无当前委托", "没有正在挂单的订单。")) { order in
                PendingOrderRowCard(order: order)
            }
        case .orders:
            stateList(viewModel.orders, empty: ("暂无历史委托", "尚未产生历史订单记录。")) { order in
                OrderRowCard(order: order)
            }
        case .fills:
            stateList(viewModel.fills, empty: ("暂无成交", "尚未产生成交记录。")) { fill in
                FillRowCard(fill: fill)
            }
        case .bills:
            stateList(viewModel.bills, empty: ("暂无流水", "尚未产生资金流水记录。")) { bill in
                BillRowCard(bill: bill)
            }
        }
    }

    @ViewBuilder
    private func stateList<Item: Identifiable>(
        _ state: LoadState<[Item]>,
        empty: (String, String),
        @ViewBuilder row: @escaping (Item) -> some View
    ) -> some View {
        switch state {
        case .idle, .loading:
            LoadingStateView()
        case .empty:
            EmptyStateView(title: empty.0, message: empty.1)
        case .failed(let message):
            ErrorStateView(message: message)
        case .loaded(let items):
            LazyVStack(spacing: 8) {
                ForEach(items) { item in row(item) }
            }
        }
    }
}
