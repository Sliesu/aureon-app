//
//  DraftStore.swift
//  aureon-app
//
//  UserDefaults 持久化：语言偏好、AI 模板聊天草稿 ID 等轻量本地状态，
//  对齐 Web 版 localStorage 用法（okx-quant-locale / AI template draft）。
//

import Foundation

/// 非隔离的全局读写点，供 `MockRepository` 的 `scenarioProvider` 闭包（可能在任意隔离域调用）
/// 与主线程 `DraftStore` 同时安全访问同一份演示场景开关。
enum MockScenarioStore {
    private static let key = "aureon.mockScenario"

    static var current: MockScenario {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key), let scenario = MockScenario(rawValue: raw) else {
                return .normal
            }
            return scenario
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}

@MainActor
final class DraftStore {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let locale = "aureon.locale"
        static let templateDraftId = "aureon.templateDraftId"
        static let dataSourceMode = "aureon.dataSourceMode"
    }

    var locale: AppLocale {
        get { AppLocale(rawValue: defaults.string(forKey: Keys.locale) ?? "") ?? .zhHans }
        set { defaults.set(newValue.rawValue, forKey: Keys.locale) }
    }

    var templateDraftId: String {
        if let existing = defaults.string(forKey: Keys.templateDraftId) { return existing }
        let generated = UUID().uuidString
        defaults.set(generated, forKey: Keys.templateDraftId)
        return generated
    }

    var mockScenario: MockScenario {
        get { MockScenarioStore.current }
        set { MockScenarioStore.current = newValue }
    }
}
