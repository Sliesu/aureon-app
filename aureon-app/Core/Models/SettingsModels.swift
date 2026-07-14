//
//  SettingsModels.swift
//  aureon-app
//
//  设置聚合负载，对齐 Web 版 workspace-settings-contract.ts 的 SettingsClientPayload。
//

import Foundation

struct StrategyGlobalConfig: Codable, Equatable {
    var enabled: Bool
    var instId: String
    var pollMs: Int
}

struct RuntimeConnectorSnapshot: Codable, Equatable {
    var llmConfigured: Bool
    var okxConfigured: Bool
    var okxSimulated: Bool
    var marketIntelConfigured: Bool
}

struct SettingsPayload: Codable, Equatable {
    var scope: WorkspaceScope
    var riskLimits: RiskLimits
    var riskSnapshot: RiskSnapshot
    var strategyConfig: StrategyGlobalConfig
    var displayPrefs: DisplayPreferences
    var pilotMinDecisionGapMs: Int
    var runtimeConnectors: RuntimeConnectorSnapshot
    var appVersion: String
}

struct ReleaseNote: Codable, Equatable, Identifiable {
    var id: String
    var version: String
    var date: Date
    var highlightsZh: [String]
}
