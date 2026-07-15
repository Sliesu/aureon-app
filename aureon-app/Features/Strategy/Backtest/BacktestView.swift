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
            strategyPickerBar

            BacktestResultSection(viewModel: viewModel)

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

    /// 策略切换菜单：支持对模板库中的任意策略执行回测，而非只能回测当前编辑草稿。
    private var strategyPickerBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Menu {
                    ForEach(viewModel.loadedTemplates) { template in
                        Button {
                            viewModel.selectTemplateForBacktest(template)
                        } label: {
                            if template.id == viewModel.isEditingTemplateId {
                                Label(template.name, systemImage: "checkmark")
                            } else {
                                Text(template.name)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.draft.style.accentGlyph).foregroundStyle(AureonPalette.gold500)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("回测策略：\(viewModel.draft.name)").font(AureonFont.body(13, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                            Text(viewModel.draft.instId).font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
                        }
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundStyle(AureonPalette.mutedSlate)
                    }
                }
                Spacer()
                Button("运行回测") { Task { await viewModel.runBacktest() } }
                    .buttonStyle(GoldCapsuleButtonStyle())
            }
            if viewModel.loadedTemplates.isEmpty {
                Text("模板库暂无可选策略，先在「模板库」创建一个。").font(AureonFont.body(11)).foregroundStyle(AureonPalette.mutedSlate)
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
