//
//  NotificationManager.swift
//  aureon-app
//
//  本地通知：策略状态变化、回测完成、风险提醒。均为本地 Mock 触发，
//  未来可无缝替换为服务端推送（APNs），接口保持一致。
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleLocal(titleZh: String, bodyZh: String, delaySeconds: TimeInterval = 1, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = titleZh
        content.body = bodyZh
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delaySeconds, 1), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func notifyStrategyStatus(templateName: String, status: RunStatus) {
        scheduleLocal(titleZh: "策略状态更新", bodyZh: "「\(templateName)」已切换为 \(status.labelZh)")
    }

    func notifyBacktestCompleted(templateName: String, totalReturnPercent: Double) {
        scheduleLocal(titleZh: "回测已完成", bodyZh: "「\(templateName)」回测总收益 \(AureonFormat.percent(totalReturnPercent))")
    }

    func notifyRiskAlert(reason: RiskRejectionReason) {
        scheduleLocal(titleZh: "风控提醒", bodyZh: reason.messageZh)
    }
}
