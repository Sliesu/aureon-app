//
//  RunDetailView.swift
//  aureon-app
//

import SwiftUI

struct RunDetailView: View {
    @Bindable var viewModel: StrategyViewModel
    let runId: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("运行订单").aureonKicker()
                    ordersSection
                    Text("Tick 日志").aureonKicker()
                    ticksSection
                }
                .padding(16)
            }
            .navigationTitle("运行详情")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await viewModel.openRunDetail(runId: runId) }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private var ordersSection: some View {
        switch viewModel.runOrders {
        case .idle, .loading: LoadingStateView()
        case .empty: EmptyStateView(title: "暂无订单", message: "该运行尚未产生订单。")
        case .failed(let message): ErrorStateView(message: message)
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
        switch viewModel.runTicks {
        case .idle, .loading: LoadingStateView()
        case .empty: EmptyStateView(title: "暂无日志", message: "该运行尚未产生 tick 日志。")
        case .failed(let message): ErrorStateView(message: message)
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
