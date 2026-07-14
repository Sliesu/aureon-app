//
//  BacktestView.swift
//  aureon-app
//
//  回测面板：标准回测、权益曲线、交易列表、Walk-forward、参数扫描、本地纸面运行。
//

import SwiftUI

struct BacktestView: View {
    @Bindable var viewModel: StrategyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("回测标的：\(viewModel.draft.instId)").font(AureonFont.body(13, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                Spacer()
                Button("运行回测") { Task { await viewModel.runBacktest() } }
                    .buttonStyle(GoldCapsuleButtonStyle())
            }

            backtestSection

            Divider().overlay(Color.white.opacity(0.06))

            HStack {
                Text("高级分析").aureonKicker()
                Spacer()
                Button("Walk-forward") { Task { await viewModel.runWalkForward() } }.buttonStyle(GhostButtonStyle())
                Button("参数扫描") { Task { await viewModel.runParamScan() } }.buttonStyle(GhostButtonStyle())
            }

            walkForwardSection
            paramScanSection

            Divider().overlay(Color.white.opacity(0.06))

            paperTradingSection
        }
    }

    @ViewBuilder
    private var backtestSection: some View {
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
                    HStack(spacing: 16) {
                        StatChip(label: "总收益", value: AureonFormat.percent(result.summary.totalReturnPercent, decimals: 1), tint: result.summary.totalReturnPercent >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                        StatChip(label: "胜率", value: AureonFormat.percent(result.summary.winRatePercent, decimals: 0, showsSign: false))
                        StatChip(label: "最大回撤", value: AureonFormat.percent(result.summary.maxDrawdownPercent, decimals: 1, showsSign: false))
                        StatChip(label: "夏普比率", value: AureonFormat.price(result.summary.sharpeRatio, decimals: 2))
                    }
                    ShareLink(item: shareText(for: result)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                EquityCurveChart(points: result.equityCurve, trades: result.trades)
                Text("交易明细（共 \(result.trades.count) 笔）").font(AureonFont.body(12, weight: .semibold)).foregroundStyle(AureonPalette.mutedSlate)
                TradeListView(trades: result.trades)
            }
        }
    }

    @ViewBuilder
    private var walkForwardSection: some View {
        switch viewModel.walkForwardResult {
        case .loaded(let result):
            WalkForwardResultView(result: result).glassCard(style: .panel)
        case .loading:
            LoadingStateView(message: "Walk-forward 分析中…")
        case .failed(let message):
            ErrorStateView(message: message)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var paramScanSection: some View {
        switch viewModel.paramScanResult {
        case .loaded(let result):
            ParamScanResultView(result: result).glassCard(style: .panel)
        case .loading:
            LoadingStateView(message: "参数扫描中…")
        case .failed(let message):
            ErrorStateView(message: message)
        default:
            EmptyView()
        }
    }

    private func shareText(for result: BacktestResult) -> String {
        "AUREON 回测摘要\n标的：\(result.request.instId)\n总收益：\(AureonFormat.percent(result.summary.totalReturnPercent, decimals: 1))\n胜率：\(AureonFormat.percent(result.summary.winRatePercent, decimals: 0, showsSign: false))\n最大回撤：\(AureonFormat.percent(result.summary.maxDrawdownPercent, decimals: 1, showsSign: false))\n（本地演示数据，非真实交易结果）"
    }

    private var paperTradingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("本地纸面运行").aureonKicker()
                PlaceholderMetricTag()
                Spacer()
                if viewModel.paperRun.status == .running {
                    Button("停止") { viewModel.stopPaperRun() }.buttonStyle(GhostButtonStyle())
                } else {
                    Button("开始纸面运行") { viewModel.startPaperRun() }.buttonStyle(GoldCapsuleButtonStyle())
                }
            }
            Text("完全在本机运行，仅依赖模拟价格流，退出页面即清空，不写入服务端。")
                .font(AureonFont.body(11))
                .foregroundStyle(AureonPalette.mutedSlate)

            if !viewModel.paperRun.equityCurve.isEmpty {
                HStack(spacing: 16) {
                    StatChip(label: "模拟权益", value: AureonFormat.currency(viewModel.paperRun.equity))
                    StatChip(label: "累计收益", value: AureonFormat.percent(viewModel.paperRun.totalReturnPercent, decimals: 2), tint: viewModel.paperRun.totalReturnPercent >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                    StatChip(label: "交易次数", value: "\(viewModel.paperRun.trades.count)")
                }
                EquityCurveChart(points: viewModel.paperRun.equityCurve)
            }
        }
        .glassCard()
    }
}
