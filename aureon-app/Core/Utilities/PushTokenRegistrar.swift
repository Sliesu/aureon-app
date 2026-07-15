//
//  PushTokenRegistrar.swift
//  aureon-app
//
//  预留 APNs 设备 token 注册接口。本仓库当前不实现推送服务端（见
//  Docs/API.md），因此默认使用 `NoOpPushTokenRegistrar` 仅记录/丢弃 token。
//
//  未来服务端就位后，实现 `PushTokenRegistering`（例如向
//  `POST /api/devices/push-token` 上报）并在 `AppEnvironment` 中替换
//  `PushTokenRegistrar.shared.registrar`，其余调用链（AppDelegate 回调、
//  NotificationManager 触发注册）无需改动。
//

import Foundation
import Observation

public struct PushTokenHex: Equatable {
    public let value: String

    public init(deviceToken: Data) {
        value = deviceToken.map { String(format: "%02x", $0) }.joined()
    }
}

/// 未来接入真实 APNs 设备注册后端时需要实现的契约。
protocol PushTokenRegistering: Sendable {
    func registerDeviceToken(_ token: PushTokenHex) async
    func registrationFailed(_ error: Error) async
}

/// 当前默认实现：不联网、不落盘，仅用于开发期确认回调链路已打通。
struct NoOpPushTokenRegistrar: PushTokenRegistering {
    func registerDeviceToken(_ token: PushTokenHex) async {
        #if DEBUG
        print("[PushTokenRegistrar] 收到 APNs device token（未接入服务端，仅记录）：\(token.value)")
        #endif
    }

    func registrationFailed(_ error: Error) async {
        #if DEBUG
        print("[PushTokenRegistrar] APNs 注册失败（预期行为：未开启 Push Notifications 能力或无网络证书）：\(error.localizedDescription)")
        #endif
    }
}

/// 供 `AppDelegate`（非 MainActor 隔离的 UIKit 回调）安全访问的全局持有者。
@MainActor
@Observable
final class PushTokenRegistrarHolder {
    static let shared = PushTokenRegistrarHolder()

    /// 最近一次收到的 token（十六进制），用于设置页展示调试信息；不做任何网络上报。
    private(set) var lastTokenHex: String?
    private(set) var lastFailureMessage: String?

    private var registrar: PushTokenRegistering = NoOpPushTokenRegistrar()

    private init() {}

    func handleRegistrationSuccess(deviceToken: Data) {
        let token = PushTokenHex(deviceToken: deviceToken)
        lastTokenHex = token.value
        lastFailureMessage = nil
        let registrar = registrar
        Task { await registrar.registerDeviceToken(token) }
    }

    func handleRegistrationFailure(error: Error) {
        lastFailureMessage = error.localizedDescription
        let registrar = registrar
        Task { await registrar.registrationFailed(error) }
    }
}
