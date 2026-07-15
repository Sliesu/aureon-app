//
//  TemplateDetailView.swift
//  aureon-app
//
//  策略详情：模板全量元信息 + 就地回测（含 AI 研判占位）。从模板库点击卡片进入，
//  「编辑」复用 `viewModel.editTemplate` 触发的既有导航机制推入编辑器。
//

import SwiftUI

struct TemplateDetailView: View {
    @Bindable var viewModel: StrategyViewModel
    let templateId: String
    let onRunStarted: () -> Void

    private var template: StrategyTemplate? {
        viewModel.loadedTemplates.first { $0.id == templateId }
    }

    var body: some View {
        ScrollView {
            if let template {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection(template)
                    metaSection(template)
                    riskSection(template)
                    ruleParamsSection(template)
                    actionsBar(template)

                    Divider().overlay(Color.white.opacity(0.06))

                    backtestSection
                }
                .padding(16)
            } else {
                EmptyStateView(title: "模板不存在", message: "该模板可能已被删除，请返回模板库。")
                    .padding(16)
            }
        }
        .navigationTitle(template?.name ?? "策略详情")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: templateId) {
            if let template { viewModel.selectTemplateForBacktest(template) }
        }
    }

    // MARK: - 头部

    private func headerSection(_ template: StrategyTemplate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.style.accentGlyph)
                    .font(.system(size: 20))
                    .foregroundStyle(AureonPalette.gold500)
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name).font(AureonFont.display(18, weight: .semibold)).foregroundStyle(AureonPalette.warmWhite)
                    Text(template.style.titleZh).font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
                }
                Spacer()
                GoldChip(text: template.instType.labelZh)
            }
            Text(template.style.descriptionZh).font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
            if let summary = template.lastBacktestSummary {
                HStack(spacing: 16) {
                    StatChip(label: "最近回测收益", value: AureonFormat.percent(summary.totalReturnPercent, decimals: 1), tint: summary.totalReturnPercent >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                    StatChip(label: "胜率", value: AureonFormat.percent(summary.winRatePercent, decimals: 0, showsSign: false))
                    StatChip(label: "最大回撤", value: AureonFormat.percent(summary.maxDrawdownPercent, decimals: 1, showsSign: false))
                }
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }

    // MARK: - 基础信息

    private func metaSection(_ template: StrategyTemplate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("基础信息").aureonKicker()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                StatChip(label: "交易对", value: template.instId)
                StatChip(label: "触发方式", value: template.frequency.kind == .interval ? "每 \(template.frequency.intervalSeconds) 秒" : (template.frequency.cronExpression ?? "Cron"))
                StatChip(label: "单笔金额", value: AureonFormat.currency(template.entrySizing.usdAmount))
                if template.instType == .swap {
                    StatChip(label: "杠杆", value: "\(Int(template.leverage))x")
                }
                StatChip(label: "创建于", value: AureonFormat.relativeTime(template.createdAt))
                StatChip(label: "更新于", value: AureonFormat.relativeTime(template.updatedAt))
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }

    // MARK: - 风控

    private func riskSection(_ template: StrategyTemplate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("风控参数").aureonKicker()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                StatChip(label: "止盈", value: AureonFormat.percent(template.risk.takeProfitPercent, decimals: 1), tint: AureonPalette.signalBuy)
                StatChip(label: "止损", value: AureonFormat.percent(-template.risk.stopLossPercent, decimals: 1, showsSign: false), tint: AureonPalette.signalSell)
                StatChip(label: "最大杠杆", value: "\(Int(template.risk.maxLeverage))x")
            }
        }
        .padding(12)
        .glassCard(style: .panel, padding: 0)
    }

    // MARK: - 规则参数

    @ViewBuilder
    private func ruleParamsSection(_ template: StrategyTemplate) -> some View {
        if !template.ruleParams.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("规则参数").aureonKicker()
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(Array(template.ruleParams.keys).sorted(), id: \.self) { key in
                        StatChip(label: key, value: "\(Int(template.ruleParams[key] ?? 0))")
                    }
                }
            }
            .padding(12)
            .glassCard(style: .panel, padding: 0)
        }
    }

    // MARK: - 操作

    private func actionsBar(_ template: StrategyTemplate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button("编辑") { viewModel.editTemplate(template) }.buttonStyle(GhostButtonStyle())
                Button("启动运行") {
                    Task {
                        if await viewModel.startRun(templateId: template.id) {
                            onRunStarted()
                        }
                    }
                }
                .buttonStyle(GoldCapsuleButtonStyle())
                Spacer()
            }
            if let startRunError = viewModel.startRunError {
                Text(startRunError).font(AureonFont.body(11)).foregroundStyle(AureonPalette.signalSell)
            }
        }
    }

    // MARK: - 就地回测

    private var backtestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("策略回测").aureonKicker()
                Spacer()
                Button("运行回测") { Task { await viewModel.runBacktest() } }.buttonStyle(GoldCapsuleButtonStyle())
            }
            BacktestResultSection(viewModel: viewModel)
        }
    }
}
