//
//  LiveActivityManager.swift
//  aureon-app
//
//  管理策略运行 / 回测的 Live Activity 生命周期（锁屏 + 灵动岛）。
//  实际 UI 渲染由 AureonWidgets Extension 中的 `AureonStrategyActivityWidget`
//  提供（见该 Target），本类只负责 request / update / end 与状态恢复。
//

import ActivityKit
import AureonShared
import Foundation

@MainActor
final class LiveActivityManager {
    private var activeActivities: [String: Activity<AureonStrategyActivityAttributes>] = [:]

    init() {
        recoverExistingActivities()
    }

    /// App 重新前台/冷启动后，把系统中仍存活的 Activity 重新纳入管理，
    /// 避免主 App 状态与系统实际展示的锁屏/灵动岛卡片不一致。
    private func recoverExistingActivities() {
        guard #available(iOS 16.1, *) else { return }
        for activity in Activity<AureonStrategyActivityAttributes>.activities {
            activeActivities[activity.attributes.runId] = activity
        }
    }

    func startOrUpdateStrategyRun(
        runId: String,
        templateName: String,
        style: StrategyStyle,
        kind: AureonStrategyActivityAttributes.ActivityKind = .strategyRun,
        statusLabelZh: String,
        progressPercent: Double,
        realizedPnlUsd: Double
    ) {
        guard #available(iOS 16.1, *) else { return }
        let state = AureonStrategyActivityAttributes.ContentState(
            statusLabelZh: statusLabelZh,
            progressPercent: progressPercent,
            realizedPnlUsd: realizedPnlUsd,
            updatedAt: .now
        )

        if let existing = activeActivities[runId] {
            Task { await existing.update(ActivityContent(state: state, staleDate: staleDate())) }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = AureonStrategyActivityAttributes(templateName: templateName, style: style.rawValue, kind: kind, runId: runId)
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: staleDate())
            )
            activeActivities[runId] = activity
        } catch {
            // 静默失败：模拟器/未授权环境下 Live Activity 不可用，不影响主流程。
        }
    }

    func endActivity(
        runId: String,
        finalStatusLabelZh: String? = nil,
        finalProgressPercent: Double? = nil,
        finalRealizedPnlUsd: Double? = nil
    ) {
        guard #available(iOS 16.1, *) else { return }
        guard let activity = activeActivities.removeValue(forKey: runId) else { return }
        Task {
            if let finalStatusLabelZh {
                let finalState = AureonStrategyActivityAttributes.ContentState(
                    statusLabelZh: finalStatusLabelZh,
                    progressPercent: finalProgressPercent ?? activity.content.state.progressPercent,
                    realizedPnlUsd: finalRealizedPnlUsd ?? activity.content.state.realizedPnlUsd,
                    updatedAt: .now
                )
                await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .after(.now.addingTimeInterval(5)))
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    /// 无服务端推送时，Activity 内容超过该时长未更新即视为「过期」，
    /// 系统会以变暗样式提示用户数据可能不是最新的。
    private func staleDate() -> Date? {
        guard #available(iOS 16.1, *) else { return nil }
        return .now.addingTimeInterval(10 * 60)
    }
}
