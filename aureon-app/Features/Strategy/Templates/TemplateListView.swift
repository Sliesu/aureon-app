//
//  TemplateListView.swift
//  aureon-app
//
//  点击卡片主体进入「策略详情」；编辑 / 启动运行作为独立按钮，避免嵌套 Button
//  吞掉外层点击手势。
//

import SwiftUI

struct TemplateListView: View {
    @Bindable var viewModel: StrategyViewModel
    let onOpenDetail: (StrategyTemplate) -> Void
    let onEdit: (StrategyTemplate) -> Void
    let onStart: (StrategyTemplate) -> Void

    var body: some View {
        switch viewModel.templates {
        case .idle, .loading:
            LoadingStateView()
        case .empty:
            EmptyStateView(title: "暂无策略模板", message: "点击右上角「新建」开始创建你的第一个策略模板。")
        case .failed(let message):
            ErrorStateView(message: message, onRetry: { Task { await viewModel.loadTemplates() } })
        case .loaded(let templates):
            LazyVStack(spacing: 10) {
                ForEach(templates) { template in
                    TemplateCard(
                        template: template,
                        onOpenDetail: { onOpenDetail(template) },
                        onEdit: { onEdit(template) },
                        onStart: { onStart(template) }
                    )
                }
            }
        }
    }
}

private struct TemplateCard: View {
    let template: StrategyTemplate
    let onOpenDetail: () -> Void
    let onEdit: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: template.style.accentGlyph).foregroundStyle(AureonPalette.gold500)
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name).font(AureonFont.body(14, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                    Text("\(template.instId) · \(template.style.titleZh)").font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
                }
                Spacer()
                GoldChip(text: template.instType.labelZh)
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(AureonPalette.mutedSlate)
            }

            if let summary = template.lastBacktestSummary {
                HStack(spacing: 16) {
                    StatChip(label: "累计收益", value: AureonFormat.percent(summary.totalReturnPercent, decimals: 1), tint: summary.totalReturnPercent >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                    StatChip(label: "胜率", value: AureonFormat.percent(summary.winRatePercent, decimals: 0, showsSign: false))
                    StatChip(label: "最大回撤", value: AureonFormat.percent(summary.maxDrawdownPercent, decimals: 1, showsSign: false))
                }
            }

            HStack(spacing: 10) {
                Button("编辑", action: onEdit).buttonStyle(GhostButtonStyle())
                Button("启动运行", action: onStart).buttonStyle(GoldCapsuleButtonStyle())
                Spacer()
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenDetail)
        .contextMenu {
            Button("查看详情", action: onOpenDetail)
            Button("编辑", action: onEdit)
            Button("启动运行", action: onStart)
        }
    }
}
