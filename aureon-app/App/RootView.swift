//
//  RootView.swift
//  aureon-app
//
//  根视图：托管五域 Tab 内容与底部液态玻璃 Dock。
//

import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedTab: AureonTab = .market
    @State private var marketRoute = MarketRoute()

    var body: some View {
        ZStack(alignment: .bottom) {
            AureonBackground()

            TabContentSwitcher(selectedTab: selectedTab, marketRoute: $marketRoute)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: AureonDockMetrics.reservedHeight)
                }

            AureonLiquidGlassDock(selectedTab: $selectedTab)
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
        }
        .ignoresSafeArea(edges: .bottom)
        .environment(\.aureonLocale, env.locale)
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

private struct TabContentSwitcher: View {
    let selectedTab: AureonTab
    @Binding var marketRoute: MarketRoute

    var body: some View {
        ZStack {
            switch selectedTab {
            case .market:
                MarketView(route: $marketRoute)
            case .account:
                AccountView()
            case .strategy:
                StrategyView()
            case .insights:
                InsightsView()
            case .profile:
                SettingsView()
            }
        }
        .transition(.opacity)
    }
}

/// 跨 Tab 共享的市场路由状态（当前 instId），用于策略/洞察继承主币种。
struct MarketRoute: Equatable {
    var instId: String = "BTC-USDT"
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
