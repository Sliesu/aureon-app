//
//  aureon_appUITests.swift
//  aureon-appUITests
//
//  UI 测试：五个 Tab 的可达性、市场快捷交易入口、策略与设置的关键控件。
//

import XCTest

final class aureon_appUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAllFiveTabsAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        let identifiers = ["market.root", "account.root", "strategy.root", "insights.root", "settings.root"]
        let tabTitles = ["市场", "账户", "策略", "洞察", "我的"]

        for (index, title) in tabTitles.enumerated() {
            let tabButton = app.buttons[title]
            if tabButton.waitForExistence(timeout: 5) {
                tabButton.tap()
            }
            let identifier = identifiers[index]
            XCTAssertTrue(app.otherElements[identifier].waitForExistence(timeout: 5) || app.descendants(matching: .any)[identifier].waitForExistence(timeout: 5), "未能定位到 \(identifier)")
        }
    }

    @MainActor
    func testMarketQuickTradeEntryExists() throws {
        let app = XCUIApplication()
        app.launch()

        let marketTab = app.buttons["市场"]
        if marketTab.waitForExistence(timeout: 5) {
            marketTab.tap()
        }
        XCTAssertTrue(app.staticTexts["模拟买入"].waitForExistence(timeout: 8) || app.buttons["模拟买入"].waitForExistence(timeout: 8))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
