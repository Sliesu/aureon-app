//
//  DeepLinkTests.swift
//  AureonSharedTests
//
//  验证 aureon:// 深链编解码与快捷操作 -> 深链的映射，覆盖快捷操作、
//  Widget/灵动岛点击、通知点击三条入口共用的路由解析逻辑。
//

import XCTest
@testable import AureonShared

final class DeepLinkTests: XCTestCase {
    func testMarketDeepLinkRoundTrip() {
        let link = AureonDeepLink.market(instId: "ETH-USDT")
        let url = link.url
        XCTAssertEqual(url.scheme, "aureon")
        XCTAssertEqual(url.host, "market")
        XCTAssertEqual(AureonDeepLink(url: url), link)
    }

    func testStrategyRunsAndNewTemplateDeepLinks() {
        XCTAssertEqual(AureonDeepLink(url: AureonDeepLink.strategyRuns.url), .strategyRuns)
        XCTAssertEqual(AureonDeepLink(url: AureonDeepLink.strategyNewTemplate.url), .strategyNewTemplate)
    }

    func testNotificationSettingsDeepLink() {
        XCTAssertEqual(AureonDeepLink(url: AureonDeepLink.notificationSettings.url), .notificationSettings)
    }

    func testInvalidSchemeIsRejected() {
        XCTAssertNil(AureonDeepLink(url: URL(string: "https://market/BTC-USDT")!))
    }

    func testMarketDeepLinkRejectsEmptyInstId() {
        XCTAssertNil(AureonDeepLink(url: URL(string: "aureon://market/")!))
    }

    func testUserInfoRoundTrip() {
        let link = AureonDeepLink.market(instId: "BTC-USDT")
        let restored = AureonDeepLink(userInfoValue: link.userInfoValue)
        XCTAssertEqual(restored, link)
    }

    func testUserInfoRoundTripHandlesNil() {
        XCTAssertNil(AureonDeepLink(userInfoValue: nil))
    }

    func testAllQuickActionTypesMapToStableDeepLinks() {
        for type in AureonQuickActionType.allCases {
            let restored = AureonDeepLink(url: type.deepLink.url)
            XCTAssertEqual(restored, type.deepLink, "快捷操作 \(type.rawValue) 的深链应可还原")
        }
    }

    func testQuickActionTypeRawValuesAreUnique() {
        let rawValues = AureonQuickActionType.allCases.map(\.rawValue)
        XCTAssertEqual(Set(rawValues).count, rawValues.count)
    }
}
