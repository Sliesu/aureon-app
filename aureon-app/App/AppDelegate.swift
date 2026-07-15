//
//  AppDelegate.swift
//  aureon-app
//
//  SwiftUI 的 `App`/`Scene` 声明式 API 不提供 Home Screen Quick Actions
//  （桌面长按快捷菜单）与 APNs 注册回调的原生钩子，因此通过
//  `@UIApplicationDelegateAdaptor` 接入最小 UIKit 桥接层：
//  - `AppDelegate` 负责 APNs 注册结果回调与场景配置。
//  - `AureonSceneDelegate` 负责冷启动 / 热启动两种路径下的快捷操作分发。
//  两者只做事件转发，业务路由逻辑统一收敛在 `AppRouter`。
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AureonQuickActionRegistrar.registerStaticShortcutsIfNeeded()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = AureonSceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushTokenRegistrarHolder.shared.handleRegistrationSuccess(deviceToken: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushTokenRegistrarHolder.shared.handleRegistrationFailure(error: error)
        }
    }
}

/// 处理桌面长按快捷操作（Quick Actions）在冷启动 / 热启动两种路径下的分发。
/// 场景生命周期下（`UIApplicationSceneManifest` 已声明），系统只通过场景
/// 委托回调传递 shortcut item，因此需要一个最小的 `UIWindowSceneDelegate`
/// 与 SwiftUI 的窗口管理共存（不手动创建 window，只补充回调）。
final class AureonSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcutItem = connectionOptions.shortcutItem {
            Task { @MainActor in AppRouter.shared.handle(shortcutItem: shortcutItem) }
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        Task { @MainActor in AppRouter.shared.handle(shortcutItem: shortcutItem) }
        completionHandler(true)
    }
}
