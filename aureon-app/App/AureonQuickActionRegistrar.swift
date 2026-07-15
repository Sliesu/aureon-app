//
//  AureonQuickActionRegistrar.swift
//  aureon-app
//
//  在应用启动时注册桌面长按快捷菜单（Home Screen Quick Actions）。使用
//  `UIApplication.shared.shortcutItems` 动态注册而非 Info.plist 静态声明，
//  使四个固定入口的标题/图标只需在 `AureonShared.AureonQuickActionType`
//  中维护一份，不会在 Swift 代码与 Info.plist 之间产生重复定义。
//

import AureonShared
import UIKit

enum AureonQuickActionRegistrar {
    static func registerStaticShortcutsIfNeeded() {
        UIApplication.shared.shortcutItems = AureonQuickActionType.allCases.map { type in
            UIApplicationShortcutItem(
                type: type.rawValue,
                localizedTitle: type.titleZh,
                localizedSubtitle: type.subtitleZh,
                icon: UIApplicationShortcutIcon(systemImageName: type.systemImageName)
            )
        }
    }
}
