//
//  AppRouter.swift
//  aureon-app
//
//  统一原生入口路由：桌面长按快捷操作（Quick Actions）、桌面小组件/灵动岛
//  点击（aureon:// URL）、本地通知点击均汇聚为同一个 `AureonDeepLink`，
//  由 `RootView` 统一消费并驱动 Tab/子路由切换。
//
//  `AppDelegate`/`AureonSceneDelegate` 在 UIKit 生命周期回调中运行，早于
//  SwiftUI 视图树建立，因此路由状态使用跨生命周期存活的单例
//  `AppRouter.shared`，再由 `AppEnvironment` 持有同一实例供 SwiftUI 观察。
//

import AureonShared
import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    /// 冷启动时可能在 SwiftUI 视图树建立之前就收到深链，先缓存，
    /// 待 `RootView` 出现后再消费一次；此后的深链通过 `onChange` 实时响应。
    var pendingDeepLink: AureonDeepLink?

    private init() {}

    func handle(url: URL) {
        guard let link = AureonDeepLink(url: url) else { return }
        pendingDeepLink = link
    }

    func handle(shortcutItem: UIApplicationShortcutItem) {
        guard let type = AureonQuickActionType(rawValue: shortcutItem.type) else { return }
        pendingDeepLink = type.deepLink
    }

    func handle(notificationUserInfo: [AnyHashable: Any]) {
        guard let raw = notificationUserInfo["aureon.deepLink"] as? String,
              let link = AureonDeepLink(userInfoValue: raw) else { return }
        pendingDeepLink = link
    }

    @discardableResult
    func consumePendingDeepLink() -> AureonDeepLink? {
        defer { pendingDeepLink = nil }
        return pendingDeepLink
    }
}
