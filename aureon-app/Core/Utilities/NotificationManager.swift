//
//  NotificationManager.swift
//  aureon-app
//
//  本地通知：策略状态变化、回测完成、风险提醒。均为本地触发，未来可无缝
//  替换为服务端推送（APNs）——`PushTokenRegistrar.swift` 已预留设备
//  token 注册接口，本类只负责本地通知的授权、展示与点击路由。
//

import AureonShared
import Foundation
import Observation
import UIKit
import UserNotifications

@MainActor
@Observable
final class NotificationManager: NSObject {
    private let center = UNUserNotificationCenter.current()

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// 通知点击后需要跳转的深链，由 `AppEnvironment` 注入，转发给 `AppRouter`。
    var deepLinkHandler: ((AureonDeepLink) -> Void)?

    override init() {
        super.init()
        center.delegate = self
        Task { await refreshAuthorizationStatus() }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// 由用户在「我的 → 通知」中主动触发，而非启动时强制弹出系统授权弹窗
    /// （遵循 Apple 关于「在使用场景中再请求权限」的建议）。授权通过后
    /// 同时调用 `registerForRemoteNotifications()`，为未来接入 APNs 预热
    /// device token 注册链路（见 `PushTokenRegistrar.swift`）。
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// 设置页「发送测试通知」按钮：验证授权、展示与点击跳转链路是否打通。
    func sendTestNotification() {
        scheduleLocal(
            titleZh: "AUREON 测试通知",
            bodyZh: "通知链路已打通，点击可跳转到通知设置页。",
            category: .riskAlert,
            deepLink: .notificationSettings
        )
    }

    private func scheduleLocal(
        titleZh: String,
        bodyZh: String,
        delaySeconds: TimeInterval = 1,
        identifier: String = UUID().uuidString,
        category: AureonNotificationCategory,
        deepLink: AureonDeepLink?
    ) {
        let content = UNMutableNotificationContent()
        content.title = titleZh
        content.body = bodyZh
        content.sound = .default
        content.categoryIdentifier = category.rawValue
        if let deepLink {
            content.userInfo = ["aureon.deepLink": deepLink.userInfoValue]
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delaySeconds, 1), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func notifyStrategyStatus(templateName: String, status: RunStatus) {
        scheduleLocal(
            titleZh: "策略状态更新",
            bodyZh: "「\(templateName)」已切换为 \(status.labelZh)",
            category: .strategyStatus,
            deepLink: .strategyRuns
        )
    }

    func notifyBacktestCompleted(templateName: String, totalReturnPercent: Double) {
        scheduleLocal(
            titleZh: "回测已完成",
            bodyZh: "「\(templateName)」回测总收益 \(AureonFormat.percent(totalReturnPercent))",
            category: .backtestCompleted,
            deepLink: .strategyRuns
        )
    }

    func notifyRiskAlert(reason: RiskRejectionReason) {
        scheduleLocal(
            titleZh: "风控提醒",
            bodyZh: reason.messageZh,
            category: .riskAlert,
            deepLink: nil
        )
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// App 前台时也展示系统通知横幅，而非静默丢弃。
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let raw = userInfo["aureon.deepLink"] as? String
        guard let link = AureonDeepLink(userInfoValue: raw) else { return }
        await MainActor.run { [weak self] in
            self?.deepLinkHandler?(link)
        }
    }
}
