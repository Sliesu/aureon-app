//
//  aureon_appTests.swift
//  aureon-appTests
//
//  单元测试：Codable 解码、Mock Repository、金额格式化、指标计算、
//  纸面运行草稿转换与风控拒绝路径。
//

import AureonShared
import UIKit
import XCTest
@testable import aureon_app

final class aureon_appTests: XCTestCase {

    // MARK: - Codable

    func testTickerSnapshotRoundTrip() throws {
        let original = TickerSnapshot(instId: "BTC-USDT", last: 64820.15, bid: 64794.23, ask: 64846.07, open24h: 63991.02, high24h: 65210.88, low24h: 63504.10, vol24h: 48211.36, ts: Date(timeIntervalSince1970: 1_752_000_000))
        let data = try AureonJSON.encoder.encode(original)
        let decoded = try AureonJSON.decoder.decode(TickerSnapshot.self, from: data)
        XCTAssertEqual(decoded.instId, original.instId)
        XCTAssertEqual(decoded.last, original.last, accuracy: 0.0001)
    }

    func testCandleCodingKeysMatchWireFormat() throws {
        let json = """
        { "ts": "2026-07-14T07:00:00.000Z", "o": 100, "h": 105, "l": 98, "c": 102, "vol": 12.5 }
        """.data(using: .utf8)!
        let candle = try AureonJSON.decoder.decode(Candle.self, from: json)
        XCTAssertEqual(candle.open, 100)
        XCTAssertEqual(candle.close, 102)
        XCTAssertEqual(candle.volume, 12.5)
    }

    func testAPIErrorEnvelopeDecoding() throws {
        let json = """
        { "code": "order_notional_exceeded", "message": "订单名义金额超出单笔上限" }
        """.data(using: .utf8)!
        let envelope = try AureonJSON.decoder.decode(APIErrorEnvelope.self, from: json)
        XCTAssertEqual(envelope.code, RiskRejectionReason.notionalExceeded.rawValue)
    }

    // MARK: - 格式化

    func testCurrencyFormatting() {
        XCTAssertEqual(AureonFormat.currency(1234.5), "$1,234.50")
        XCTAssertEqual(AureonFormat.percent(3.456, decimals: 1), "+3.5%")
        XCTAssertEqual(AureonFormat.percent(-3.456, decimals: 1), "-3.5%")
    }

    func testCompactUsdFormatting() {
        XCTAssertEqual(AureonFormat.compactUsd(2_500_000_000_000), "$2.50T")
        XCTAssertEqual(AureonFormat.compactUsd(-1_500), "-$1.5K")
    }

    // MARK: - Mock Repository

    func testMockRepositoryReturnsDeterministicCandles() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let candles = try await repository.fetchCandles(instId: "BTC-USDT", bar: .fifteenMinutes, limit: 50)
        XCTAssertEqual(candles.count, 50)
        XCTAssertTrue(candles.allSatisfy { $0.high >= $0.low })
    }

    func testMockRepositoryEmptyScenario() async throws {
        let repository = MockRepository(scenarioProvider: { .empty })
        let watchlist = try await repository.fetchWatchlist()
        XCTAssertTrue(watchlist.isEmpty)
        let templates = try await repository.fetchTemplates()
        XCTAssertTrue(templates.isEmpty)
    }

    func testMockRepositoryServiceErrorScenario() async {
        let repository = MockRepository(scenarioProvider: { .serviceError })
        do {
            _ = try await repository.fetchTemplates()
            XCTFail("应当抛出服务错误")
        } catch let error as NetworkError {
            switch error {
            case .server: break
            default: XCTFail("错误类型不匹配：\(error)")
            }
        } catch {
            XCTFail("意外错误类型：\(error)")
        }
    }

    func testMockRepositoryOrderRiskRejection() async {
        let repository = MockRepository(scenarioProvider: { .riskRejected })
        do {
            _ = try await repository.placeOrder(instId: "BTC-USDT", instType: .spot, side: .buy, sizeUsd: 100, leverage: 1)
            XCTFail("应当抛出风控拒绝错误")
        } catch let envelope as APIErrorEnvelope {
            XCTAssertEqual(envelope.code, RiskRejectionReason.notionalExceeded.rawValue)
        } catch {
            XCTFail("意外错误类型：\(error)")
        }
    }

    func testMockRepositoryTemplateCRUD() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let existing = try await repository.fetchTemplates()
        let draft = StrategyTemplateDraft(style: .balanced)
        let created = try await repository.createTemplate(draft.toTemplate(existingId: nil))
        let afterCreate = try await repository.fetchTemplates()
        XCTAssertEqual(afterCreate.count, existing.count + 1)

        try await repository.deleteTemplate(id: created.id)
        let afterDelete = try await repository.fetchTemplates()
        XCTAssertEqual(afterDelete.count, existing.count)
    }

    // MARK: - 策略草稿

    func testStrategyTemplateDraftConversion() {
        var draft = StrategyTemplateDraft(style: .dualMa)
        draft.takeProfitPercent = 8
        draft.stopLossPercent = 4
        let template = draft.toTemplate(existingId: "tpl-test")
        XCTAssertEqual(template.id, "tpl-test")
        XCTAssertEqual(template.risk.takeProfitPercent, 8)
        XCTAssertEqual(template.style, .dualMa)

        let request = draft.toBacktestRequest()
        XCTAssertEqual(request.risk.stopLossPercent, 4)
    }

    // MARK: - 纸面运行状态机

    func testPaperRunStateReturnCalculation() {
        var state = PaperRunState()
        state.equity = 11_000
        XCTAssertEqual(state.totalReturnPercent, 10, accuracy: 0.001)
    }

    // MARK: - 原生入口路由（快捷操作 / Widget / 通知 -> AppRouter）

    @MainActor
    func testAppRouterHandlesDeepLinkURL() {
        let router = AppRouter.shared
        router.pendingDeepLink = nil
        router.handle(url: AureonDeepLink.market(instId: "ETH-USDT").url)
        XCTAssertEqual(router.pendingDeepLink, .market(instId: "ETH-USDT"))
        XCTAssertEqual(router.consumePendingDeepLink(), .market(instId: "ETH-USDT"))
        XCTAssertNil(router.pendingDeepLink)
    }

    @MainActor
    func testAppRouterHandlesNotificationUserInfo() {
        let router = AppRouter.shared
        router.pendingDeepLink = nil
        router.handle(notificationUserInfo: ["aureon.deepLink": AureonDeepLink.strategyRuns.userInfoValue])
        XCTAssertEqual(router.pendingDeepLink, .strategyRuns)
    }

    @MainActor
    func testAppRouterHandlesShortcutItem() {
        let router = AppRouter.shared
        router.pendingDeepLink = nil
        let item = UIApplicationShortcutItem(type: AureonQuickActionType.newStrategyTemplate.rawValue, localizedTitle: "新建策略")
        router.handle(shortcutItem: item)
        XCTAssertEqual(router.pendingDeepLink, .strategyNewTemplate)
    }

    @MainActor
    func testAppRouterIgnoresUnknownShortcutType() {
        let router = AppRouter.shared
        router.pendingDeepLink = nil
        let item = UIApplicationShortcutItem(type: "com.unknown.type", localizedTitle: "未知")
        router.handle(shortcutItem: item)
        XCTAssertNil(router.pendingDeepLink)
    }

    @MainActor
    func testAppRouterIgnoresUnrelatedNotificationPayload() {
        let router = AppRouter.shared
        router.pendingDeepLink = nil
        router.handle(notificationUserInfo: ["someOtherKey": "value"])
        XCTAssertNil(router.pendingDeepLink)
    }
}
