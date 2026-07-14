//
//  RunListView.swift
//  aureon-app
//
//  运行实例列表：状态、暂停/恢复/停止、进入详情查看订单与 tick 日志。
//

import SwiftUI

struct RunListView: View {
    @Bindable var viewModel: StrategyViewModel
    @State private var openDetailRunId: String?

    var body: some View {
        Group {
            switch viewModel.runs {
            case .idle, .loading:
                LoadingStateView()
            case .empty:
                EmptyStateView(title: "暂无运行实例", message: "在「模板」中启动一个策略以开始运行。")
            case .failed(let message):
                ErrorStateView(message: message, onRetry: { Task { await viewModel.loadRuns() } })
            case .loaded(let runs):
                LazyVStack(spacing: 10) {
                    ForEach(runs) { run in
                        RunCard(run: run, onPause: { Task { await viewModel.setRunStatus(runId: run.id, status: .paused) } },
                                onResume: { Task { await viewModel.setRunStatus(runId: run.id, status: .running) } },
                                onStop: { Task { await viewModel.setRunStatus(runId: run.id, status: .stopped) } },
                                onOpenDetail: { openDetailRunId = run.id })
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { openDetailRunId.map { RunDetailTarget(id: $0) } },
            set: { openDetailRunId = $0?.id }
        )) { target in
            RunDetailView(viewModel: viewModel, runId: target.id)
        }
    }
}

private struct RunDetailTarget: Identifiable { let id: String }

private struct RunCard: View {
    let run: TemplateRun
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onOpenDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: run.style.accentGlyph).foregroundStyle(AureonPalette.gold500)
                VStack(alignment: .leading, spacing: 2) {
                    Text(run.templateName).font(AureonFont.body(14, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                    Text(run.instId).font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
                }
                Spacer()
                StatusBadge(text: run.status.labelZh, tint: run.status.tintKey)
            }

            HStack(spacing: 16) {
                StatChip(label: "已实现盈亏", value: AureonFormat.currency(run.realizedPnlUsd), tint: run.realizedPnlUsd >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                if let nextFire = run.nextFireAt {
                    StatChip(label: "下次触发", value: AureonFormat.relativeTime(nextFire))
                }
                if run.execFailStreak > 0 {
                    StatChip(label: "连续失败", value: "\(run.execFailStreak)", tint: AureonPalette.signalSell)
                }
            }

            HStack(spacing: 10) {
                if run.status == .running {
                    Button("暂停", action: onPause).buttonStyle(GhostButtonStyle())
                } else if run.status == .paused {
                    Button("恢复", action: onResume).buttonStyle(GhostButtonStyle())
                }
                if run.status != .stopped {
                    Button("停止", action: onStop).buttonStyle(GhostButtonStyle())
                }
                Spacer()
                Button("详情", action: onOpenDetail).buttonStyle(GhostButtonStyle())
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }
}
