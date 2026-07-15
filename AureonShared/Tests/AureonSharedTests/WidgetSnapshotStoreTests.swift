//
//  WidgetSnapshotStoreTests.swift
//  AureonSharedTests
//
//  验证 App Group 共享快照的读写往返（单元测试环境无 App Group 权限时
//  会自动回落到 `.standard`，见 `AureonAppGroup.sharedDefaults`）。
//

import XCTest
@testable import AureonShared

final class WidgetSnapshotStoreTests: XCTestCase {
    override func tearDown() {
        WidgetSnapshotStore.updateWatchlist([])
        WidgetSnapshotStore.updateStrategySummary(nil)
        super.tearDown()
    }

    func testWatchlistRoundTrip() {
        let items = [
            WatchlistWidgetSnapshot(instId: "BTC-USDT", last: 64_820, changePercent24h: 1.8),
            WatchlistWidgetSnapshot(instId: "ETH-USDT", last: 3_180, changePercent24h: -0.6)
        ]
        WidgetSnapshotStore.updateWatchlist(items)
        XCTAssertEqual(WidgetSnapshotStore.readWatchlist(), items)
    }

    func testStrategySummaryRoundTrip() {
        let snapshot = StrategyWidgetSnapshot(runningCount: 2, topTemplateName: "BTC 稳健定投", topRealizedPnlUsd: 214.6, updatedAt: Date(timeIntervalSince1970: 1_752_000_000))
        WidgetSnapshotStore.updateStrategySummary(snapshot)
        XCTAssertEqual(WidgetSnapshotStore.readStrategySummary(), snapshot)
    }

    func testStrategySummaryClearedWhenSetToNil() {
        WidgetSnapshotStore.updateStrategySummary(StrategyWidgetSnapshot(runningCount: 1, topTemplateName: "临时模板", topRealizedPnlUsd: 10, updatedAt: .now))
        WidgetSnapshotStore.updateStrategySummary(nil)
        XCTAssertNil(WidgetSnapshotStore.readStrategySummary())
    }

    func testEmptyWatchlistReadsAsEmptyArray() {
        WidgetSnapshotStore.updateWatchlist([])
        XCTAssertEqual(WidgetSnapshotStore.readWatchlist(), [])
    }
}
