//
//  InsightsView.swift
//  aureon-app
//
//  洞察域主视图：一键评估、建议历史、宏观/新闻/情报/订单簿、审计时间线。
//

import SwiftUI

struct InsightsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: InsightsViewModel?

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
            .navigationTitle("洞察")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if viewModel == nil {
                let vm = InsightsViewModel(instId: "BTC-USDT", repository: env.repository, haptics: env.haptics)
                viewModel = vm
                await vm.loadAll()
            }
        }
        .accessibilityIdentifier("insights.root")
    }

    @ViewBuilder
    private func content(viewModel: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(kicker: "AUREON VAULT", title: "洞察工作台", subtitle: "AI/规则建议、宏观上下文与审计追踪，均为本地演示数据。")
                .padding(.horizontal, 16)
                .padding(.top, 8)

            HStack {
                Text(viewModel.instId).font(AureonFont.mono(14, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                Spacer()
                Button {
                    Task { await viewModel.evaluate() }
                } label: {
                    if viewModel.isEvaluating {
                        ProgressView().tint(.black)
                    } else {
                        Text("运行 AI 评估")
                    }
                }
                .buttonStyle(GoldCapsuleButtonStyle())
                .disabled(viewModel.isEvaluating)
            }
            .padding(.horizontal, 16)

            if viewModel.metrics.isPlaceholder {
                HStack {
                    PlaceholderMetricTag()
                    Text("准确率统计当前为演示占位（样本量 \(viewModel.metrics.sampleSize)），非真实统计结果。")
                        .font(AureonFont.body(10))
                        .foregroundStyle(AureonPalette.mutedSlate)
                }
                .padding(.horizontal, 16)
            }

            historySection.padding(.horizontal, 16)

            if case .loaded(let macro) = viewModel.macro {
                MacroOverviewCard(macro: macro).padding(.horizontal, 16)
            }

            if case .loaded(let intel) = viewModel.marketIntel {
                MarketIntelCard(intel: intel).padding(.horizontal, 16)
            }

            if case .loaded(let book) = viewModel.orderBook {
                OrderBookMiniView(snapshot: book).padding(.horizontal, 16)
            }

            headlinesSection.padding(.horizontal, 16)
            auditSection.padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("建议历史").aureonKicker()
            switch viewModel?.history ?? .idle {
            case .idle, .loading: LoadingStateView()
            case .empty: EmptyStateView(title: "暂无建议历史", message: "点击「运行 AI 评估」生成首条建议。")
            case .failed(let message): ErrorStateView(message: message)
            case .loaded(let records):
                LazyVStack(spacing: 8) {
                    ForEach(records) { AdviceRecordCard(record: $0) }
                }
            }
        }
    }

    @ViewBuilder
    private var headlinesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("市场新闻").aureonKicker()
            switch viewModel?.headlines ?? .idle {
            case .idle, .loading: LoadingStateView()
            case .empty: EmptyStateView(title: "暂无新闻", message: "")
            case .failed(let message): ErrorStateView(message: message)
            case .loaded(let items): HeadlinesListView(headlines: items)
            }
        }
    }

    @ViewBuilder
    private var auditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("审计时间线").aureonKicker()
            switch viewModel?.audit ?? .idle {
            case .idle, .loading: LoadingStateView()
            case .empty: EmptyStateView(title: "暂无审计记录", message: "")
            case .failed(let message): ErrorStateView(message: message)
            case .loaded(let events): AuditTimelineView(events: events).glassCard(style: .panel)
            }
        }
    }
}
