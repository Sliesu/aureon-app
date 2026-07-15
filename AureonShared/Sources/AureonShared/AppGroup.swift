//
//  AppGroup.swift
//  AureonShared
//
//  主 App 与 AureonWidgets Extension 共享的 App Group 标识符。
//  需在 Apple Developer 后台注册该 App Group，并在两个 Target 的
//  「Signing & Capabilities → App Groups」中勾选启用，详见仓库 README。
//

import Foundation

public enum AureonAppGroup {
    public static let identifier = "group.com.rbc.aureon-app"

    /// 共享 UserDefaults 容器；未开启 App Groups 能力时（如未签名的模拟器调试）
    /// 回退到 `.standard`，保证主 App 单独运行时不崩溃。
    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
