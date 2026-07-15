//
//  RootView.swift
//  aureon-app
//
//  根视图：托管五域 Tab 内容与底部液态玻璃 Dock。
//

import AureonShared
import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedTab: AureonTab = .market
    @State private var marketRoute = MarketRoute()
    @State private var strategyRoute = StrategyRoute()

    var body: some View {
        ZStack {
            AureonBackground()

            TabView(selection: $selectedTab) {
                Tab(AureonTab.market.titleZh, systemImage: AureonTab.market.systemImage, value: AureonTab.market) {
                    MarketView(route: $marketRoute)
                }

                Tab(AureonTab.account.titleZh, systemImage: AureonTab.account.systemImage, value: AureonTab.account) {
                    AccountView()
                }

                Tab(AureonTab.strategy.titleZh, systemImage: AureonTab.strategy.systemImage, value: AureonTab.strategy) {
                    StrategyView(route: $strategyRoute)
                }

                Tab(AureonTab.insights.titleZh, systemImage: AureonTab.insights.systemImage, value: AureonTab.insights) {
                    InsightsView()
                }

                Tab(AureonTab.profile.titleZh, systemImage: AureonTab.profile.systemImage, value: AureonTab.profile) {
                    SettingsView()
                }
            }
            .tint(AureonPalette.dockSelected)
        }
        .environment(\.aureonLocale, env.locale)
        .task {
            apply(env.router.consumePendingDeepLink())
        }
        .onChange(of: env.router.pendingDeepLink) { _, newValue in
            apply(newValue)
        }
    }

    /// 把快捷操作 / Widget 深链 / 通知点击统一路由到对应 Tab 与子路由。
    private func apply(_ link: AureonDeepLink?) {
        guard let link else { return }
        switch link {
        case .market(let instId):
            marketRoute.instId = instId
            selectedTab = .market
        case .strategyRuns:
            strategyRoute.requestedSection = .runs
            selectedTab = .strategy
        case .strategyNewTemplate:
            strategyRoute.requestedSection = .newTemplate
            selectedTab = .strategy
        case .notificationSettings:
            selectedTab = .profile
        }
        env.router.pendingDeepLink = nil
    }
}

/// 五个一级功能域，映射 Web 版 AppShell 的 `/dashboard /account /strategy /advice /settings`。
enum AureonTab: String, CaseIterable, Identifiable, Hashable {
    case market
    case account
    case strategy
    case insights
    case profile

    var id: String { rawValue }

    var titleZh: String {
        switch self {
        case .market: return "市场"
        case .account: return "账户"
        case .strategy: return "策略"
        case .insights: return "洞察"
        case .profile: return "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .market: return "waveform.path.ecg"
        case .account: return "creditcard.and.123"
        case .strategy: return "chart.line.uptrend.xyaxis"
        case .insights: return "sparkles"
        case .profile: return "person.crop.circle"
        }
    }
}

/// 跨 Tab 共享的市场路由状态（当前 instId），用于策略/洞察继承主币种。
struct MarketRoute: Equatable {
    var instId: String = "BTC-USDT"
}

/// 策略 Tab 的深链请求：来自快捷操作 / Widget / 通知点击，被消费后应清空。
struct StrategyRoute: Equatable {
    enum Section: Equatable {
        case runs
        case newTemplate
    }

    var requestedSection: Section?
}

private struct AureonLocaleKey: EnvironmentKey {
    static let defaultValue: AppLocale = .zhHans
}

extension EnvironmentValues {
    var aureonLocale: AppLocale {
        get { self[AureonLocaleKey.self] }
        set { self[AureonLocaleKey.self] = newValue }
    }
}
