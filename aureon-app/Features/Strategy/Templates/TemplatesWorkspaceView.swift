//
//  TemplatesWorkspaceView.swift
//  aureon-app
//
//  模板库 → 独立编辑页：选中模板后明确绑定当前模板，保存/回测/启动运行均针对
//  该上下文；启动成功后自动切换到运行中心。替代此前「列表 + 内嵌编辑器」的堆叠布局。
//

import SwiftUI

struct TemplatesWorkspaceView: View {
    @Bindable var viewModel: StrategyViewModel
    let onRunStarted: () -> Void
    @State private var showEditor = false
    @State private var detailTarget: TemplateDetailTarget?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("已有模板").aureonKicker()
                Spacer()
                Button("新建模板") { viewModel.beginNewDraft(style: .balanced) }
                    .buttonStyle(GhostButtonStyle())
            }
            if let startRunError = viewModel.startRunError {
                Text(startRunError).font(AureonFont.body(11)).foregroundStyle(AureonPalette.signalSell)
            }
            TemplateListView(
                viewModel: viewModel,
                onOpenDetail: { detailTarget = TemplateDetailTarget(id: $0.id) },
                onEdit: { viewModel.editTemplate($0) },
                onStart: { template in
                    Task {
                        if await viewModel.startRun(templateId: template.id) {
                            onRunStarted()
                        }
                    }
                }
            )
        }
        .navigationDestination(item: $detailTarget) { target in
            TemplateDetailView(viewModel: viewModel, templateId: target.id, onRunStarted: onRunStarted)
        }
        .navigationDestination(isPresented: $showEditor) {
            TemplateEditorPageView(viewModel: viewModel, onRunStarted: onRunStarted)
        }
        // 外部入口（总览「新建模板」快捷动作）可能在本视图出现之前就已写入
        // pendingTemplateNavigation，仅靠 onChange 无法捕获「首次出现时已是非 nil」
        // 的情况，因此额外用 task 在出现时主动检查一次。跨区域打开某个模板详情
        // 改由 `StrategyView` 直接把 `TemplateDetailTarget` 推入顶层导航栈完成，
        // 不再经过这里的异步消费，避免「先跳模板库再跳详情」的双重 push 时序问题。
        .task { consumePendingEditorRequest() }
        .onChange(of: viewModel.pendingTemplateNavigation) { _, _ in consumePendingEditorRequest() }
    }

    private func consumePendingEditorRequest() {
        guard viewModel.pendingTemplateNavigation != nil else { return }
        showEditor = true
        viewModel.pendingTemplateNavigation = nil
    }
}

struct TemplateDetailTarget: Identifiable, Hashable {
    let id: String
}

/// 模板编辑页：绑定 `viewModel.draft`，展示保存反馈、脏数据提示，
/// 并提供回测/启动运行的上下文入口。
private struct TemplateEditorPageView: View {
    @Bindable var viewModel: StrategyViewModel
    let onRunStarted: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.isDraftDirty {
                HStack(spacing: 6) {
                    Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(AureonPalette.signalHold)
                    Text("有未保存的改动")
                        .font(AureonFont.body(11))
                        .foregroundStyle(AureonPalette.signalHold)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            } else if let savedAt = viewModel.draftSavedAt {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 11)).foregroundStyle(AureonPalette.signalBuy)
                    Text("已于 \(AureonFormat.relativeTime(savedAt)) 保存")
                        .font(AureonFont.body(11))
                        .foregroundStyle(AureonPalette.mutedSlate)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            if let error = viewModel.draftSaveError {
                Text(error).font(AureonFont.body(11)).foregroundStyle(AureonPalette.signalSell).padding(.horizontal, 16)
            }

            TemplateEditorView(viewModel: viewModel)

            if let existingId = viewModel.isEditingTemplateId {
                Divider().overlay(Color.white.opacity(0.06))
                HStack {
                    Text("绑定模板：\(viewModel.draft.name)").font(AureonFont.body(12)).foregroundStyle(AureonPalette.mutedSlate)
                    Spacer()
                    Button("启动运行") {
                        Task {
                            if await viewModel.startRun(templateId: existingId) {
                                onRunStarted()
                            }
                        }
                    }
                    .buttonStyle(GoldCapsuleButtonStyle())
                }
                .padding(16)
                if let startRunError = viewModel.startRunError {
                    Text(startRunError).font(AureonFont.body(11)).foregroundStyle(AureonPalette.signalSell).padding(.horizontal, 16)
                }
            }
        }
        .navigationTitle(viewModel.isEditingTemplateId == nil ? "新建模板" : "编辑模板")
        .navigationBarTitleDisplayMode(.inline)
    }
}
