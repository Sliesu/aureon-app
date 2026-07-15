//
//  BacktestResultSection.swift
//  aureon-app
//
//  回测结果展示：摘要指标、权益曲线、交易明细与 AI 研判占位，供「策略回测」
//  与「策略详情」共用，避免同一套逻辑在两处重复维护。
//

import SwiftUI

struct BacktestResultSection: View {
    @Bindable var viewModel: StrategyViewModel

    var body: some View {
        switch viewModel.backtestResult {
        case .idle:
            EmptyStateView(glyph: "play.rectangle", title: "尚未运行回测", message: "点击「运行回测」查看权益曲线与交易明细。")
        case .loading:
            LoadingStateView(message: "正在回测…")
        case .empty:
            EmptyStateView(title: "无可用历史数据", message: "该标的暂无足够历史 K 线用于回测。")
        case .failed(let message):
            ErrorStateView(message: message, onRetry: { Task { await viewModel.runBacktest() } })
        case .loaded(let result):
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 10) {
                        StatChip(label: "总收益", value: AureonFormat.percent(result.summary.totalReturnPercent, decimals: 1), tint: result.summary.totalReturnPercent >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                        StatChip(label: "胜率", value: AureonFormat.percent(result.summary.winRatePercent, decimals: 0, showsSign: false))
                        StatChip(label: "最大回撤", value: AureonFormat.percent(result.summary.maxDrawdownPercent, decimals: 1, showsSign: false))
                        StatChip(label: "夏普比率", value: AureonFormat.price(result.summary.sharpeRatio, decimals: 2))
                    }
                    Spacer()
                    ShareLink(item: shareText(for: result)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                EquityCurveChart(points: result.equityCurve, trades: result.trades)
                Text("交易明细（共 \(result.trades.count) 笔）").font(AureonFont.body(12, weight: .semibold)).foregroundStyle(AureonPalette.mutedSlate)
                TradeListView(trades: result.trades)

                AIResearchCard(viewModel: viewModel)
            }
        }
    }

    private func shareText(for result: BacktestResult) -> String {
        "AUREON 回测摘要\n标的：\(result.request.instId)\n总收益：\(AureonFormat.percent(result.summary.totalReturnPercent, decimals: 1))\n胜率：\(AureonFormat.percent(result.summary.winRatePercent, decimals: 0, showsSign: false))\n最大回撤：\(AureonFormat.percent(result.summary.maxDrawdownPercent, decimals: 1, showsSign: false))\n（本地演示数据，非真实交易结果）"
    }
}

/// AI 研判占位卡片：结构已就位（按钮 → ViewModel → Provider），但当前
/// `NoOpBacktestAIResearchProvider` 尚未接入真实 LLM 后端，因此不展示任何
/// 伪造的分析结论，仅诚实说明「即将上线」。
private struct AIResearchCard: View {
    @Bindable var viewModel: StrategyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AI 研判").aureonKicker()
                GoldChip(text: "待接入 API")
                Spacer()
                if case .loading = viewModel.aiResearch {
                    ProgressView().controlSize(.small)
                } else {
                    Button("生成 AI 研判") { Task { await viewModel.requestAIResearch() } }
                        .buttonStyle(GhostButtonStyle())
                }
            }

            switch viewModel.aiResearch {
            case .idle:
                Text("基于本次回测的买卖点、风险与优化建议将在此展示，需接入后端 LLM 服务后启用。")
                    .font(AureonFont.body(12))
                    .foregroundStyle(AureonPalette.mutedSlate)
            case .loading:
                Text("正在生成研判…").font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
            case .empty:
                Text("暂无可用研判内容。").font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
            case .failed(let message):
                Text(message).font(AureonFont.body(12)).foregroundStyle(AureonPalette.signalHold)
            case .loaded(let research):
                VStack(alignment: .leading, spacing: 8) {
                    Text(research.summaryZh).font(AureonFont.body(13)).foregroundStyle(AureonPalette.warmWhite)
                    if !research.riskNotesZh.isEmpty {
                        ForEach(research.riskNotesZh, id: \.self) { note in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundStyle(AureonPalette.signalSell)
                                Text(note).font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
                            }
                        }
                    }
                    if !research.suggestionsZh.isEmpty {
                        ForEach(research.suggestionsZh, id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "lightbulb.fill").font(.system(size: 10)).foregroundStyle(AureonPalette.gold500)
                                Text(suggestion).font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}
