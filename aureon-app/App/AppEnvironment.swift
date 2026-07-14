//
//  AppEnvironment.swift
//  aureon-app
//
//  应用级依赖容器：数据仓库、原生服务与全局工作区状态。
//  首个版本默认使用 MockRepository 驱动；后续可无缝切换到 LiveAPIClient。
//

import Foundation
import Observation

/// 数据来源模式。Mock 完全离线可用；Live 面向未来真实后端（当前仓库未实现服务端）。
enum DataSourceMode: String, CaseIterable, Identifiable, Hashable {
    case mock
    case live

    var id: String { rawValue }

    var displayNameZh: String {
        switch self {
        case .mock: return "本地演示数据"
        case .live: return "真实后端（未配置）"
        }
    }
}

@MainActor
@Observable
final class AppEnvironment {
    /// 当前数据源模式，默认 Mock，可在「我的 → API 环境」中切换。
    var dataSourceMode: DataSourceMode = .mock

    /// 全局工作区策略（交易模式 / 自动化模式 / 租户模式），来自设置域。
    var workspaceScope: WorkspaceScope = .default

    /// 全局风控限额快照。
    var riskLimits: RiskLimits = .default

    /// 显示偏好（报价币种、小数位、金额脱敏阈值等）。
    var displayPrefs: DisplayPreferences = .default

    /// 当前语言（zh-Hans / en）。
    var locale: AppLocale = .zhHans

    /// 全局风险快照（持仓名义、当日已实现盈亏、最后下单时间）。
    var riskSnapshot: RiskSnapshot = .empty

    /// 模拟盘 / 实盘状态展示（演示用途，不持有真实凭据）。
    var connectionStatus: ConnectionStatus = .simulatedDemo

    private(set) var repository: DataRepository
    let biometrics = BiometricAuthManager()
    let haptics = HapticsManager()
    let notifications = NotificationManager()
    let draftStore = DraftStore()
    let liveActivity = LiveActivityManager()

    /// 真实后端 Base URL（用户在「我的 → API 环境」中填写，留空则数据源强制回落为 Mock）。
    var liveBaseURLString: String = ""

    init(repository: DataRepository? = nil) {
        self.repository = repository ?? MockRepository(scenarioProvider: { MockScenarioStore.current })
        self.locale = draftStore.locale
        Task { await bootstrap() }
        Task { await notifications.requestAuthorizationIfNeeded() }
    }

    private func bootstrap() async {
        if let settings = try? await repository.fetchSettings() {
            workspaceScope = settings.scope
            riskLimits = settings.riskLimits
            displayPrefs = settings.displayPrefs
            riskSnapshot = settings.riskSnapshot
        }
    }

    func applyScope(_ scope: WorkspaceScope) {
        workspaceScope = scope
        haptics.impact(.light)
    }

    func applyRiskLimits(_ limits: RiskLimits) {
        riskLimits = limits
        haptics.impact(.light)
    }

    func applyDisplayPrefs(_ prefs: DisplayPreferences) {
        displayPrefs = prefs
    }

    func applyLocale(_ locale: AppLocale) {
        self.locale = locale
        draftStore.locale = locale
    }

    /// 切换数据源：Mock 始终可用；Live 仅在填写 Base URL 后生效，否则保持 Mock 并提示未配置。
    func switchDataSource(_ mode: DataSourceMode, baseURLString: String = "") {
        switch mode {
        case .mock:
            dataSourceMode = .mock
            repository = MockRepository(scenarioProvider: { MockScenarioStore.current })
        case .live:
            guard let url = URL(string: baseURLString), !baseURLString.isEmpty else {
                dataSourceMode = .mock
                return
            }
            liveBaseURLString = baseURLString
            dataSourceMode = .live
            repository = LiveAPIClient(baseURL: url)
        }
        Task { await bootstrap() }
    }

    func setMockScenario(_ scenario: MockScenario) {
        draftStore.mockScenario = scenario
        Task { await bootstrap() }
    }
}

enum AppLocale: String, CaseIterable, Identifiable, Hashable {
    case zhHans = "zh-Hans"
    case en = "en"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .zhHans: return "中文"
        case .en: return "English"
        }
    }
}

struct ConnectionStatus: Equatable {
    var okxSimulated: Bool
    var okxConfigured: Bool
    var llmConfigured: Bool
    var lastSyncedAt: Date?

    static let simulatedDemo = ConnectionStatus(
        okxSimulated: true,
        okxConfigured: true,
        llmConfigured: true,
        lastSyncedAt: .now
    )
}
