//
//  RunDetailView.swift
//  aureon-app
//
//  独立可导航的运行详情页：每个 run 拥有自己的本地加载状态并并发拉取订单/Tick，
//  消除多次快速切换详情时的数据覆盖竞态；终态仅展示历史，不提供任何生命周期操作。
//

import SwiftUI

struct RunDetailView: View {
    @Bindable var viewModel: StrategyViewModel
    let runId: String

    @State private var ordersState: LoadState<[TemplateOrderRow]> = .idle
    @State private var ticksState: LoadState<[TemplateRunTick]> = .idle
    @State private var showArchiveConfirm = false

    private var run: TemplateRun? { viewModel.run(withId: runId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let run {
                    metaSection(run)
                    actionsBar(run)
                }
                Text("运行订单").aureonKicker()
                ordersSection
                Text("Tick 日志").aureonKicker()
                ticksSection
            }
            .padding(16)
        }
        .navigationTitle(run?.templateName ?? "运行详情")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: runId) {
            await reload()
        }
        .confirmationDialog(
            "结束并归档该运行？",
            isPresented: $showArchiveConfirm,
            titleVisibility: .visible
        ) {
            Button("结束并归档", role: .destructive) {
                Task { await viewModel.performRunAction(runId: runId, action: .archive) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("归档后不可恢复，需要在模板库重新启动才能创建新实例。")
        }
    }

    private func reload() async {
        ordersState = .loading
        ticksState = .loading
        async let ordersResult: Void = loadOrders()
        async let ticksResult: Void = loadTicks()
        _ = await (ordersResult, ticksResult)
    }

    private func loadOrders() async {
        do {
            let orders = try await viewModel.fetchRunOrders(runId: runId)
            ordersState = orders.isEmpty ? .empty : .loaded(orders)
        } catch {
            ordersState = .failed(error.localizedDescription)
        }
    }

    private func loadTicks() async {
        do {
            let ticks = try await viewModel.fetchRunTicks(runId: runId)
            ticksState = ticks.isEmpty ? .empty : .loaded(ticks)
        } catch {
            ticksState = .failed(error.localizedDescription)
        }
    }

    @ViewBuilder
    private func metaSection(_ run: TemplateRun) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: run.style.accentGlyph).foregroundStyle(AureonPalette.gold500)
                VStack(alignment: .leading, spacing: 2) {
                    Text(run.templateName).font(AureonFont.body(15, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                    Text(run.instId).font(AureonFont.mono(12)).foregroundStyle(AureonPalette.mutedSlate)
                }
                Spacer()
                StatusBadge(text: run.status.labelZh, tint: run.status.tintKey)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                StatChip(label: "已实现盈亏", value: AureonFormat.currency(run.realizedPnlUsd), tint: run.realizedPnlUsd >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                StatChip(label: "启动于", value: AureonFormat.relativeTime(run.startedAt))
                if let nextFire = run.nextFireAt {
                    StatChip(label: "下次触发", value: AureonFormat.relativeTime(nextFire))
                }
                if run.execFailStreak > 0 {
                    StatChip(label: "连续失败", value: "\(run.execFailStreak)", tint: AureonPalette.signalSell)
                }
            }
            if let errorMessage = viewModel.runActionErrors[run.id] {
                Text(errorMessage).font(AureonFont.body(11)).foregroundStyle(AureonPalette.signalSell)
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }

    @ViewBuilder
    private func actionsBar(_ run: TemplateRun) -> some View {
        let actions = Array(run.status.availableActions).sorted(by: { $0.rawValue < $1.rawValue })
        if !actions.isEmpty {
            HStack(spacing: 10) {
                ForEach(actions, id: \.self) { action in
                    let handler = {
                        if action.requiresConfirmation {
                            showArchiveConfirm = true
                        } else {
                            Task { await viewModel.performRunAction(runId: run.id, action: action) }
                        }
                    }
                    if action == .archive {
                        Button(action.titleZh, action: handler).buttonStyle(GhostButtonStyle())
                            .disabled(viewModel.pendingRunActions.contains(run.id))
                    } else {
                        Button(action.titleZh, action: handler).buttonStyle(GoldCapsuleButtonStyle())
                            .disabled(viewModel.pendingRunActions.contains(run.id))
                    }
                }
                if viewModel.pendingRunActions.contains(run.id) {
                    ProgressView().controlSize(.small)
                }
            }
        } else {
            Text("该运行已处于终态，仅可查看历史记录。").font(AureonFont.body(11)).foregroundStyle(AureonPalette.mutedSlate)
        }
    }

    @ViewBuilder
    private var ordersSection: some View {
        switch ordersState {
        case .idle, .loading: LoadingStateView()
        case .empty: EmptyStateView(title: "暂无订单", message: "该运行尚未产生订单。")
        case .failed(let message): ErrorStateView(message: message, onRetry: { Task { await loadOrders() } })
        case .loaded(let orders):
            VStack(spacing: 6) {
                ForEach(orders) { order in
                    HStack {
                        StatusBadge(text: order.side.labelZh, tint: order.side == .buy ? .buy : .sell)
                        Text(AureonFormat.price(order.price)).font(AureonFont.mono(12))
                        Spacer()
                        Text(AureonFormat.relativeTime(order.createdAt)).font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
                }
            }
        }
    }

    @ViewBuilder
    private var ticksSection: some View {
        switch ticksState {
        case .idle, .loading: LoadingStateView()
        case .empty: EmptyStateView(title: "暂无日志", message: "该运行尚未产生 tick 日志。")
        case .failed(let message): ErrorStateView(message: message, onRetry: { Task { await loadTicks() } })
        case .loaded(let ticks):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(ticks) { tick in
                    HStack(alignment: .top, spacing: 8) {
                        if let signal = tick.signal {
                            StatusBadge(text: signal.labelZh, tint: signal == .buy ? .buy : (signal == .sell ? .sell : .hold))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tick.messageZh).font(AureonFont.body(12)).foregroundStyle(AureonPalette.warmWhite)
                            Text(AureonFormat.relativeTime(tick.occurredAt)).font(AureonFont.mono(10)).foregroundStyle(AureonPalette.mutedSlate)
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
                }
            }
        }
    }
}
