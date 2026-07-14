//
//  PilotView.swift
//  aureon-app
//
//  AI Pilot 主视图：会话列表、持仓、挂单、决策日志、新建会话表单。
//

import SwiftUI

struct PilotView: View {
    @Bindable var viewModel: PilotViewModel
    @State private var showCreateSheet = false
    @State private var expandedSessionId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Pilot 会话").aureonKicker()
                Spacer()
                Button {
                    showCreateSheet = true
                } label: {
                    Label("新建会话", systemImage: "plus.circle.fill")
                }
                .buttonStyle(GhostButtonStyle())
            }

            sessionsSection

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("持仓").aureonKicker()
                    holdingsSection
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("挂单").aureonKicker()
                    pendingOrdersSection
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            PilotSessionFormView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var sessionsSection: some View {
        switch viewModel.sessions {
        case .idle, .loading: LoadingStateView()
        case .empty: EmptyStateView(title: "暂无 Pilot 会话", message: "新建一个会话以启动 AI 自主决策巡航。")
        case .failed(let message): ErrorStateView(message: message, onRetry: { Task { await viewModel.loadSessions() } })
        case .loaded(let sessions):
            LazyVStack(spacing: 10) {
                ForEach(sessions) { session in
                    PilotSessionCard(
                        session: session,
                        isExpanded: expandedSessionId == session.id,
                        onToggleExpand: {
                            expandedSessionId = expandedSessionId == session.id ? nil : session.id
                            if expandedSessionId != nil { Task { await viewModel.loadDecisions(sessionId: session.id) } }
                        },
                        onPause: { Task { await viewModel.setStatus(sessionId: session.id, status: .paused) } },
                        onResume: { Task { await viewModel.setStatus(sessionId: session.id, status: .running) } },
                        onStop: { Task { await viewModel.setStatus(sessionId: session.id, status: .stopped) } },
                        decisions: viewModel.decisionsBySession[session.id] ?? .idle
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var holdingsSection: some View {
        switch viewModel.holdings {
        case .idle, .loading: LoadingStateView()
        case .empty: EmptyStateView(glyph: "briefcase", title: "无持仓", message: "")
        case .failed(let message): ErrorStateView(message: message)
        case .loaded(let holdings):
            VStack(spacing: 6) {
                ForEach(holdings) { holding in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(holding.instId).font(AureonFont.mono(12, weight: .semibold))
                        Text(AureonFormat.currency(holding.unrealizedPnlUsd))
                            .font(AureonFont.mono(11))
                            .foregroundStyle(holding.unrealizedPnlUsd >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .glassCard(style: .panel, padding: 0)
                }
            }
        }
    }

    @ViewBuilder
    private var pendingOrdersSection: some View {
        switch viewModel.pendingOrders {
        case .idle, .loading: LoadingStateView()
        case .empty: EmptyStateView(glyph: "tray", title: "无挂单", message: "")
        case .failed(let message): ErrorStateView(message: message)
        case .loaded(let orders):
            VStack(spacing: 6) {
                ForEach(orders) { order in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.instId).font(AureonFont.mono(12, weight: .semibold))
                            Text(AureonFormat.price(order.price)).font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
                        }
                        Spacer()
                        Button("撤单") { Task { await viewModel.cancelOrder(id: order.id) } }
                            .buttonStyle(GhostButtonStyle())
                            .font(.system(size: 10))
                    }
                    .padding(8)
                    .glassCard(style: .panel, padding: 0)
                }
            }
        }
    }
}

private struct PilotSessionCard: View {
    let session: AiPilotSession
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let decisions: LoadState<[AiPilotDecision]>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name).font(AureonFont.body(14, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                    Text(session.instId).font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
                }
                Spacer()
                if session.autoExecute { GoldChip(text: "自动执行") }
                StatusBadge(text: session.status.labelZh, tint: session.status == .running ? .buy : .hold)
            }

            HStack(spacing: 10) {
                if session.status == .running {
                    Button("暂停", action: onPause).buttonStyle(GhostButtonStyle())
                } else if session.status != .stopped {
                    Button("启动", action: onResume).buttonStyle(GhostButtonStyle())
                }
                if session.status != .stopped {
                    Button("停止", action: onStop).buttonStyle(GhostButtonStyle())
                }
                Spacer()
                Button(isExpanded ? "收起日志" : "查看决策日志", action: onToggleExpand).buttonStyle(GhostButtonStyle())
            }

            if isExpanded {
                DecisionLogView(state: decisions)
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}

private struct DecisionLogView: View {
    let state: LoadState<[AiPilotDecision]>

    var body: some View {
        switch state {
        case .idle, .loading: LoadingStateView(message: "加载决策日志…")
        case .empty: EmptyStateView(title: "暂无决策", message: "该会话尚未产生决策记录。")
        case .failed(let message): ErrorStateView(message: message)
        case .loaded(let decisions):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(decisions) { decision in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            StatusBadge(text: decision.action.labelZh, tint: decision.action == .buy ? .buy : (decision.action == .sell ? .sell : .hold))
                            Text("置信度 \(Int(decision.confidencePercent))%").font(AureonFont.mono(10)).foregroundStyle(AureonPalette.mutedSlate)
                            if decision.executed { GoldChip(text: "已执行") }
                            Spacer()
                        }
                        Text(decision.reasoningZh).font(AureonFont.body(12)).foregroundStyle(AureonPalette.warmWhite.opacity(0.9))
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
                }
            }
        }
    }
}
