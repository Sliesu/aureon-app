//
//  MarketView.swift
//  aureon-app
//
//  市场域主视图：自选、实时报价、K 线/指标/回放、AI 摘要、模拟下单入口。
//  在 iPad 上使用 split 布局，在紧凑宽度上使用单列滚动，适配安全区与 Dynamic Type。
//

import SwiftUI

struct MarketView: View {
    @Binding var route: MarketRoute
    @Environment(AppEnvironment.self) private var env
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel: MarketViewModel?
    @State private var showOrderSheet = false
    @State private var orderConfirmationMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let viewModel {
                    content(viewModel: viewModel)
                } else {
                    LoadingStateView()
                }
            }
            .refreshable {
                await viewModel?.loadAll()
            }
            .navigationTitle("市场")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.clear)
        }
        .task {
            if viewModel == nil {
                let vm = MarketViewModel(instId: route.instId, repository: env.repository, haptics: env.haptics)
                viewModel = vm
                await vm.loadAll()
            }
        }
        .onDisappear { viewModel?.stopStream() }
        .sheet(isPresented: $showOrderSheet) {
            if let viewModel {
                PlaceOrderSheet(
                    instId: viewModel.instId,
                    lastPrice: viewModel.ticker?.last,
                    scope: env.workspaceScope,
                    riskLimits: env.riskLimits,
                    isSubmitting: viewModel.isPlacingOrder,
                    errorMessage: viewModel.orderErrorMessage,
                    onSubmit: { side, sizeUsd, instType, leverage in
                        await viewModel.placeSimulatedOrder(side: side, sizeUsd: sizeUsd, instType: instType, leverage: leverage)
                        if viewModel.lastOrderConfirmation != nil {
                            orderConfirmationMessage = "\(side.labelZh)成交：$\(Int(sizeUsd))"
                            showOrderSheet = false
                        }
                    },
                    onDismiss: { showOrderSheet = false }
                )
            }
        }
        .alert("模拟下单成功", isPresented: .constant(orderConfirmationMessage != nil), presenting: orderConfirmationMessage) { _ in
            Button("好") { orderConfirmationMessage = nil }
        } message: { message in
            Text(message)
        }
        .accessibilityIdentifier("market.root")
    }

    @ViewBuilder
    private func content(viewModel: MarketViewModel) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(kicker: "AUREON VAULT", title: "市场工作台", subtitle: "实时行情、K 线与模拟下单，全部数据来自本地演示。")
                .padding(.horizontal, 16)
                .padding(.top, 8)

            watchlistSection(viewModel: viewModel)
                .padding(.horizontal, 16)

            TickerHeaderCard(
                instId: viewModel.instId,
                ticker: viewModel.ticker,
                liveness: viewModel.liveness,
                isWatched: viewModel.watchlist.value?.contains { $0.instId == viewModel.instId } ?? false,
                onToggleWatch: { Task { await viewModel.toggleWatchlist() } }
            )
            .padding(.horizontal, 16)

            if horizontalSizeClass == .regular {
                HStack(alignment: .top, spacing: 16) {
                    chartSection(viewModel: viewModel).frame(maxWidth: .infinity)
                    VStack(spacing: 16) {
                        AIInsightCard(state: viewModel.aiSummary) { Task { await viewModel.requestAISummary() } }
                        orderEntry(viewModel: viewModel)
                    }
                    .frame(width: 300)
                }
                .padding(.horizontal, 16)
            } else {
                chartSection(viewModel: viewModel).padding(.horizontal, 16)
                AIInsightCard(state: viewModel.aiSummary) { Task { await viewModel.requestAISummary() } }
                    .padding(.horizontal, 16)
                orderEntry(viewModel: viewModel)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 24)
    }

    private func watchlistSection(viewModel: MarketViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("自选").aureonKicker()
            switch viewModel.watchlist {
            case .loaded(let items):
                WatchlistStrip(items: items.map(\.instId), selectedInstId: viewModel.instId) { instId in
                    Task { await viewModel.changeInstrument(to: instId) }
                }
            case .empty:
                Text("暂无自选，可在下方添加常用交易对。").font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
                WatchlistStrip(items: MockMarketFactory.supportedInstruments, selectedInstId: viewModel.instId) { instId in
                    Task { await viewModel.changeInstrument(to: instId) }
                }
            case .failed:
                WatchlistStrip(items: MockMarketFactory.supportedInstruments, selectedInstId: viewModel.instId) { instId in
                    Task { await viewModel.changeInstrument(to: instId) }
                }
            default:
                LoadingStateView(message: "加载自选…")
            }
        }
    }

    @ViewBuilder
    private func chartSection(viewModel: MarketViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            IntervalPicker(interval: Bindable(viewModel).interval, indicators: Bindable(viewModel).indicatorsEnabled)

            switch viewModel.candles {
            case .loading, .idle:
                LoadingStateView(message: "加载 K 线…")
            case .empty:
                EmptyStateView(title: "暂无 K 线数据", message: "该交易对在当前周期暂无历史数据。")
            case .failed(let message):
                ErrorStateView(message: message, onRetry: { Task { await viewModel.loadCandles() } })
            case .loaded:
                CandleChartView(
                    candles: viewModel.visibleCandles,
                    emaFast: viewModel.emaFast,
                    emaSlow: viewModel.emaSlow,
                    indicators: viewModel.indicatorsEnabled,
                    selectedCandle: Bindable(viewModel).selectedCandle
                )

                if let selected = viewModel.selectedCandle {
                    HStack(spacing: 14) {
                        StatChip(label: "开", value: AureonFormat.price(selected.open))
                        StatChip(label: "高", value: AureonFormat.price(selected.high))
                        StatChip(label: "低", value: AureonFormat.price(selected.low))
                        StatChip(label: "收", value: AureonFormat.price(selected.close))
                    }
                }

                ReplayControlBar(
                    isReplaying: viewModel.isReplaying,
                    onToggle: { viewModel.toggleReplay() },
                    onStepBack: { viewModel.stepReplay(by: -3) },
                    onStepForward: { viewModel.stepReplay(by: 3) }
                )
            }
        }
        .glassCard()
    }

    private func orderEntry(viewModel: MarketViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("快捷操作").aureonKicker()
            HStack(spacing: 10) {
                Button("模拟买入") { showOrderSheet = true }
                    .buttonStyle(SemanticActionButtonStyle(tint: .buy))
                Button("模拟卖出") { showOrderSheet = true }
                    .buttonStyle(SemanticActionButtonStyle(tint: .sell))
            }
        }
        .glassCard(style: .panel)
        .accessibilityIdentifier("market.quickTrade")
    }
}
