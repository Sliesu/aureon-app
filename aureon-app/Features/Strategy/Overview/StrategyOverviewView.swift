//
//  StrategyOverviewView.swift
//  aureon-app
//
//  策略工作台默认入口：聚合运行 KPI、活跃策略、最近回测与模板快捷入口，
//  基于 `templates` / `runs` / `backtestResult` 的真实数据（不额外伪造指标）。
//

import SwiftUI

struct StrategyOverviewView: View {
    @Bindable var viewModel: StrategyViewModel
    let onNavigate: (StrategyWorkbenchSection) -> Void
    let onOpenTemplateDetail: (StrategyTemplate) -> Void
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(kicker: "AUREON VAULT", title: "策略工作台", subtitle: "模板研发、回测验证与 AI 自主巡航，均为本地演示。")

                if env.workspaceScope.tradingMode == .spot {
                    Text("当前为仅现货模式，部分衍生品策略能力将受限。")
                        .font(AureonFont.body(11))
                        .foregroundStyle(AureonPalette.signalHold)
                }

                kpiSection

                quickActionsSection

                activeRunsSection

                recentBacktestSection

                templatesPreviewSection
            }
            .padding(16)
        }
        .refreshable { await viewModel.loadAll() }
    }

    // MARK: - KPI

    private var kpiSection: some View {
        let runs = loadedRuns
        let runningCount = runs.filter { $0.status == .running }.count
        let pausedCount = runs.filter { $0.status == .paused }.count
        let errorCount = runs.filter { $0.status == .error }.count
        let activePnl = runs.filter { !$0.status.isTerminal }.reduce(0) { $0 + $1.realizedPnlUsd }

        return VStack(alignment: .leading, spacing: 10) {
            Text("运行概览").aureonKicker()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                StatChip(label: "运行中", value: "\(runningCount)", tint: AureonPalette.signalBuy)
                StatChip(label: "已暂停", value: "\(pausedCount)", tint: AureonPalette.signalHold)
                StatChip(label: "活跃策略盈亏", value: AureonFormat.currency(activePnl), tint: activePnl >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                StatChip(label: "异常实例", value: "\(errorCount)", tint: errorCount > 0 ? AureonPalette.signalSell : AureonPalette.warmWhite)
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }

    // MARK: - 快捷动作

    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    viewModel.beginNewDraft(style: .balanced)
                    onNavigate(.templates)
                } label: {
                    Label("新建模板", systemImage: "plus.circle.fill").lineLimit(1)
                }
                .buttonStyle(GoldCapsuleButtonStyle())
                .fixedSize()

                Button { onNavigate(.runs) } label: {
                    Label("运行中心", systemImage: "bolt.horizontal.circle").lineLimit(1)
                }
                .buttonStyle(GhostButtonStyle())
                .fixedSize()

                Button { onNavigate(.backtest) } label: {
                    Label("策略回测", systemImage: "chart.xyaxis.line").lineLimit(1)
                }
                .buttonStyle(GhostButtonStyle())
                .fixedSize()
            }
        }
        .scrollClipDisabled()
    }

    // MARK: - 活跃运行预览

    @ViewBuilder
    private var activeRunsSection: some View {
        let activeRuns = loadedRuns.filter { !$0.status.isTerminal }
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("活跃运行").aureonKicker()
                Spacer()
                Button("查看全部") { onNavigate(.runs) }.buttonStyle(GhostButtonStyle())
            }
            switch viewModel.runs {
            case .idle, .loading:
                LoadingStateView()
            case .failed(let message):
                ErrorStateView(message: message, onRetry: { Task { await viewModel.loadRuns() } })
            case .empty:
                EmptyStateView(glyph: "bolt.horizontal.circle", title: "暂无运行实例", message: "在「模板库」中选择一个模板并启动运行。")
            case .loaded:
                if activeRuns.isEmpty {
                    EmptyStateView(glyph: "pause.circle", title: "暂无活跃运行", message: "所有实例均已归档，可在模板库重新启动。")
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                        ForEach(activeRuns.prefix(4)) { run in
                            OverviewRunPreviewCard(run: run)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 最近回测

    @ViewBuilder
    private var recentBacktestSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("最近回测").aureonKicker()
                Spacer()
                Button("前往策略回测") { onNavigate(.backtest) }.buttonStyle(GhostButtonStyle())
            }
            switch viewModel.backtestResult {
            case .loaded(let result):
                HStack(spacing: 16) {
                    StatChip(label: "总收益", value: AureonFormat.percent(result.summary.totalReturnPercent, decimals: 1), tint: result.summary.totalReturnPercent >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                    StatChip(label: "胜率", value: AureonFormat.percent(result.summary.winRatePercent, decimals: 0, showsSign: false))
                    StatChip(label: "最大回撤", value: AureonFormat.percent(result.summary.maxDrawdownPercent, decimals: 1, showsSign: false))
                }
                .padding(12)
                .glassCard(style: .panel, padding: 0)
            default:
                EmptyStateView(glyph: "play.rectangle", title: "尚未运行回测", message: "前往策略回测，验证策略草稿的历史表现。")
            }
        }
    }

    // MARK: - 模板快捷入口

    @ViewBuilder
    private var templatesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("模板库").aureonKicker()
                Spacer()
                Button("查看全部") { onNavigate(.templates) }.buttonStyle(GhostButtonStyle())
            }
            switch viewModel.templates {
            case .idle, .loading:
                LoadingStateView()
            case .failed(let message):
                ErrorStateView(message: message, onRetry: { Task { await viewModel.loadTemplates() } })
            case .empty:
                EmptyStateView(title: "暂无策略模板", message: "点击「新建模板」创建你的第一个策略模板。")
            case .loaded(let templates):
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(templates.prefix(4)) { template in
                        OverviewTemplatePreviewCard(template: template) {
                            onOpenTemplateDetail(template)
                        }
                    }
                }
            }
        }
    }

    private var loadedRuns: [TemplateRun] {
        if case .loaded(let list) = viewModel.runs { return list }
        return []
    }
}

private struct OverviewRunPreviewCard: View {
    let run: TemplateRun

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: run.style.accentGlyph).foregroundStyle(AureonPalette.gold500)
                Text(run.templateName).font(AureonFont.body(13, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                Spacer()
                StatusBadge(text: run.status.labelZh, tint: run.status.tintKey)
            }
            HStack(spacing: 12) {
                StatChip(label: "已实现盈亏", value: AureonFormat.currency(run.realizedPnlUsd), tint: run.realizedPnlUsd >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                if let nextFire = run.nextFireAt {
                    StatChip(label: "下次触发", value: AureonFormat.relativeTime(nextFire))
                }
            }
        }
        .padding(10)
        .glassCard(style: .panel, padding: 0)
    }
}

private struct OverviewTemplatePreviewCard: View {
    let template: StrategyTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: template.style.accentGlyph).foregroundStyle(AureonPalette.gold500)
                    Text(template.name).font(AureonFont.body(13, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(AureonPalette.mutedSlate)
                }
                Text("\(template.instId) · \(template.style.titleZh)").font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
                if let summary = template.lastBacktestSummary {
                    StatChip(label: "累计收益", value: AureonFormat.percent(summary.totalReturnPercent, decimals: 1), tint: summary.totalReturnPercent >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(style: .panel, padding: 0)
        }
        .buttonStyle(.plain)
    }
}
