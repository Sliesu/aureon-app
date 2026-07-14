//
//  LiveActivityManager.swift
//  aureon-app
//
//  管理策略运行 / 回测的 Live Activity 生命周期。API 调用本身无需 Widget
//  Extension 即可安全执行（在不支持或未授权的设备上静默忽略）；但锁屏 /
//  灵动岛的自定义外观渲染需要额外的 Widget Extension Target 提供
//  ActivityConfiguration，当前云端环境无法通过命令行创建该 Xcode Target，
//  详见 README「原生能力与已知限制」。
//

import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    private var activeActivities: [String: Activity<AureonStrategyActivityAttributes>] = [:]

    func startOrUpdateStrategyRun(runId: String, templateName: String, style: StrategyStyle, statusLabelZh: String, progressPercent: Double, realizedPnlUsd: Double) {
        guard #available(iOS 16.1, *) else { return }
        let state = AureonStrategyActivityAttributes.ContentState(
            statusLabelZh: statusLabelZh,
            progressPercent: progressPercent,
            realizedPnlUsd: realizedPnlUsd,
            updatedAt: .now
        )

        if let existing = activeActivities[runId] {
            Task { await existing.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = AureonStrategyActivityAttributes(templateName: templateName, style: style.rawValue, kind: .strategyRun)
        do {
            let activity = try Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: nil))
            activeActivities[runId] = activity
        } catch {
            // 静默失败：模拟器/未授权环境下 Live Activity 不可用，不影响主流程。
        }
    }

    func endActivity(runId: String) {
        guard #available(iOS 16.1, *) else { return }
        guard let activity = activeActivities.removeValue(forKey: runId) else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
