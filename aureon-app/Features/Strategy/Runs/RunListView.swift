//
//  RunListView.swift
//  aureon-app
//
//  运行中心：分「活跃运行 / 历史归档」两区；操作按钮严格由状态机
//  （`RunStatus.availableActions`）生成，归档前二次确认，操作中禁用重复点击。
//

import SwiftUI

struct RunListView: View {
    @Bindable var viewModel: StrategyViewModel
    @State private var navigationTarget: RunDetailTarget?
    @State private var pendingArchiveRunId: String?

    var body: some View {
        Group {
            switch viewModel.runs {
            case .idle, .loading:
                LoadingStateView()
            case .empty:
                EmptyStateView(glyph: "bolt.horizontal.circle", title: "暂无运行实例", message: "在「模板库」中选择一个模板并启动运行。")
            case .failed(let message):
                ErrorStateView(message: message, onRetry: { Task { await viewModel.loadRuns() } })
            case .loaded(let runs):
                let active = runs.filter { !$0.status.isTerminal }
                let archived = runs.filter { $0.status.isTerminal }
                LazyVStack(alignment: .leading, spacing: 18) {
                    section(title: "活跃运行（\(active.count)）", runs: active, emptyMessage: "暂无运行中或已暂停的实例。")
                    section(title: "历史归档（\(archived.count)）", runs: archived, emptyMessage: "尚无已归档 / 已完成 / 异常的历史实例。")
                }
            }
        }
        .navigationDestination(item: $navigationTarget) { target in
            RunDetailView(viewModel: viewModel, runId: target.id)
        }
        .confirmationDialog(
            "结束并归档该运行？",
            isPresented: Binding(get: { pendingArchiveRunId != nil }, set: { if !$0 { pendingArchiveRunId = nil } }),
            titleVisibility: .visible
        ) {
            Button("结束并归档", role: .destructive) {
                if let runId = pendingArchiveRunId {
                    Task { await viewModel.performRunAction(runId: runId, action: .archive) }
                }
                pendingArchiveRunId = nil
            }
            Button("取消", role: .cancel) { pendingArchiveRunId = nil }
        } message: {
            Text("归档后不可恢复，需要在模板库重新启动才能创建新实例。")
        }
    }

    @ViewBuilder
    private func section(title: String, runs: [TemplateRun], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).aureonKicker()
            if runs.isEmpty {
                Text(emptyMessage).font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12)], spacing: 12) {
                    ForEach(runs) { run in
                        RunCard(
                            run: run,
                            isPending: viewModel.pendingRunActions.contains(run.id),
                            errorMessage: viewModel.runActionErrors[run.id],
                            onAction: { action in
                                if action.requiresConfirmation {
                                    pendingArchiveRunId = run.id
                                } else {
                                    Task { await viewModel.performRunAction(runId: run.id, action: action) }
                                }
                            },
                            onOpenDetail: { navigationTarget = RunDetailTarget(id: run.id) }
                        )
                    }
                }
            }
        }
    }
}

struct RunDetailTarget: Identifiable, Hashable {
    let id: String
}

private struct RunCard: View {
    let run: TemplateRun
    let isPending: Bool
    let errorMessage: String?
    let onAction: (RunLifecycleAction) -> Void
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

            if let errorMessage {
                Text(errorMessage).font(AureonFont.body(11)).foregroundStyle(AureonPalette.signalSell)
            }

            HStack(spacing: 10) {
                ForEach(Array(run.status.availableActions).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { action in
                    if action == .archive {
                        Button(action.titleZh) { onAction(action) }.buttonStyle(GhostButtonStyle()).disabled(isPending)
                    } else {
                        Button(action.titleZh) { onAction(action) }.buttonStyle(GoldCapsuleButtonStyle()).disabled(isPending)
                    }
                }
                if isPending {
                    ProgressView().controlSize(.small)
                }
                Spacer()
                Button("详情", action: onOpenDetail).buttonStyle(GhostButtonStyle())
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
        .opacity(isPending ? 0.7 : 1)
    }
}
