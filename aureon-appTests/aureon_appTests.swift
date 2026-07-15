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

    // MARK: - 运行生命周期状态机（RunLifecycleAction）

    func testRunStatusAvailableActionsMatrix() {
        XCTAssertEqual(RunStatus.running.availableActions, [.pause, .archive])
        XCTAssertEqual(RunStatus.paused.availableActions, [.resume, .archive])
        XCTAssertEqual(RunStatus.stopped.availableActions, [])
        XCTAssertEqual(RunStatus.completed.availableActions, [])
        XCTAssertEqual(RunStatus.error.availableActions, [])
    }

    func testRunStatusTerminalAndActiveFlags() {
        XCTAssertFalse(RunStatus.running.isTerminal)
        XCTAssertFalse(RunStatus.paused.isTerminal)
        XCTAssertTrue(RunStatus.stopped.isTerminal)
        XCTAssertTrue(RunStatus.completed.isTerminal)
        XCTAssertTrue(RunStatus.error.isTerminal)

        XCTAssertTrue(RunStatus.running.isActive)
        XCTAssertTrue(RunStatus.paused.isActive)
        XCTAssertFalse(RunStatus.stopped.isActive)
    }

    func testRunLifecycleActionResultingStatus() {
        XCTAssertEqual(RunLifecycleAction.pause.resultingStatus, .paused)
        XCTAssertEqual(RunLifecycleAction.resume.resultingStatus, .running)
        XCTAssertEqual(RunLifecycleAction.archive.resultingStatus, .stopped)
        XCTAssertTrue(RunLifecycleAction.archive.requiresConfirmation)
        XCTAssertFalse(RunLifecycleAction.pause.requiresConfirmation)
    }

    func testMockRepositoryPerformRunActionValidTransitions() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let template = try await repository.fetchTemplates().first!
        let run = try await repository.startRun(templateId: template.id)
        XCTAssertEqual(run.status, .running)
        XCTAssertNotNil(run.nextFireAt)

        let paused = try await repository.performRunAction(runId: run.id, action: .pause)
        XCTAssertEqual(paused.status, .paused)
        XCTAssertNil(paused.nextFireAt)

        let resumed = try await repository.performRunAction(runId: run.id, action: .resume)
        XCTAssertEqual(resumed.status, .running)
        XCTAssertNotNil(resumed.nextFireAt)

        let archived = try await repository.performRunAction(runId: run.id, action: .archive)
        XCTAssertEqual(archived.status, .stopped)
        XCTAssertNil(archived.nextFireAt)
    }

    func testMockRepositoryPerformRunActionRejectsIllegalTransition() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let template = try await repository.fetchTemplates().first!
        let run = try await repository.startRun(templateId: template.id)

        // 运行中状态不允许 resume（只能 pause/archive）。
        do {
            _ = try await repository.performRunAction(runId: run.id, action: .resume)
            XCTFail("应当拒绝非法状态跃迁")
        } catch let envelope as APIErrorEnvelope {
            XCTAssertEqual(envelope.code, "invalid_run_transition")
        }

        // 归档后为终态，任何后续动作都应被拒绝。
        _ = try await repository.performRunAction(runId: run.id, action: .archive)
        do {
            _ = try await repository.performRunAction(runId: run.id, action: .resume)
            XCTFail("终态运行不应允许恢复")
        } catch let envelope as APIErrorEnvelope {
            XCTAssertEqual(envelope.code, "invalid_run_transition")
        }
    }

    func testMockRepositoryPerformRunActionNotFoundRun() async {
        let repository = MockRepository(scenarioProvider: { .normal })
        do {
            _ = try await repository.performRunAction(runId: "missing-run", action: .pause)
            XCTFail("应当抛出未找到错误")
        } catch let envelope as APIErrorEnvelope {
            XCTAssertEqual(envelope.code, "not_found")
        } catch {
            XCTFail("意外错误类型：\(error)")
        }
    }

    func testMockRepositoryStartRunRejectsDuplicateActiveInstance() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let template = try await repository.fetchTemplates().first!
        _ = try await repository.startRun(templateId: template.id)
        do {
            _ = try await repository.startRun(templateId: template.id)
            XCTFail("同一模板存在活跃实例时应拒绝重复启动")
        } catch let envelope as APIErrorEnvelope {
            XCTAssertEqual(envelope.code, "active_run_exists")
        } catch {
            XCTFail("意外错误类型：\(error)")
        }
    }

    func testMockRepositoryStartRunAllowedAfterArchive() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let template = try await repository.fetchTemplates().first!
        let run = try await repository.startRun(templateId: template.id)
        _ = try await repository.performRunAction(runId: run.id, action: .archive)
        let secondRun = try await repository.startRun(templateId: template.id)
        XCTAssertNotEqual(secondRun.id, run.id)
        XCTAssertEqual(secondRun.status, .running)
    }

    // MARK: - StrategyViewModel 生命周期动作（副作用一致性）

    @MainActor
    func testStrategyViewModelPerformRunActionUpdatesLocalListOnSuccess() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let viewModel = StrategyViewModel(repository: repository, notifications: NotificationManager(), haptics: HapticsManager())
        await viewModel.loadRuns()
        guard case .loaded(let initialRuns) = viewModel.runs, let target = initialRuns.first(where: { $0.status == .running }) else {
            return XCTFail("演示数据应至少存在一个运行中的实例")
        }

        await viewModel.performRunAction(runId: target.id, action: .pause)

        guard case .loaded(let updatedRuns) = viewModel.runs, let updated = updatedRuns.first(where: { $0.id == target.id }) else {
            return XCTFail("动作成功后应保留该运行实例")
        }
        XCTAssertEqual(updated.status, .paused)
        XCTAssertNil(viewModel.runActionErrors[target.id])
        XCTAssertFalse(viewModel.pendingRunActions.contains(target.id))
    }

    @MainActor
    func testStrategyViewModelPerformRunActionFailureDoesNotMutateLocalState() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let viewModel = StrategyViewModel(repository: repository, notifications: NotificationManager(), haptics: HapticsManager())
        await viewModel.loadRuns()
        guard case .loaded(let initialRuns) = viewModel.runs, let target = initialRuns.first(where: { $0.status == .running }) else {
            return XCTFail("演示数据应至少存在一个运行中的实例")
        }

        // running 状态不允许 resume，仓库层应拒绝，ViewModel 不应改变本地状态。
        await viewModel.performRunAction(runId: target.id, action: .resume)

        guard case .loaded(let unchangedRuns) = viewModel.runs, let unchanged = unchangedRuns.first(where: { $0.id == target.id }) else {
            return XCTFail("失败后运行实例应仍存在于列表中")
        }
        XCTAssertEqual(unchanged.status, .running, "失败的生命周期动作不应修改本地运行状态")
        XCTAssertNotNil(viewModel.runActionErrors[target.id])
    }

    // MARK: - 策略回测：跨模板切换与 AI 研判占位

    @MainActor
    func testSelectTemplateForBacktestSwitchesDraftAndClearsPriorResults() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let viewModel = StrategyViewModel(repository: repository, notifications: NotificationManager(), haptics: HapticsManager())
        await viewModel.loadTemplates()
        guard case .loaded(let templates) = viewModel.templates, templates.count >= 2 else {
            return XCTFail("演示数据应至少存在两个模板")
        }
        let first = templates[0]
        let second = templates[1]

        viewModel.selectTemplateForBacktest(first)
        XCTAssertEqual(viewModel.isEditingTemplateId, first.id)
        await viewModel.runBacktest()
        guard case .loaded = viewModel.backtestResult else {
            return XCTFail("回测应成功产生结果")
        }

        viewModel.selectTemplateForBacktest(second)
        XCTAssertEqual(viewModel.isEditingTemplateId, second.id)
        XCTAssertEqual(viewModel.backtestResult, .idle, "切换回测标的应清空上一个策略的回测结果，避免误读")
        XCTAssertEqual(viewModel.aiResearch, .idle)
    }

    @MainActor
    func testRequestAIResearchWithoutBacktestResultDoesNothing() async {
        let repository = MockRepository(scenarioProvider: { .normal })
        let viewModel = StrategyViewModel(repository: repository, notifications: NotificationManager(), haptics: HapticsManager())
        await viewModel.requestAIResearch()
        XCTAssertEqual(viewModel.aiResearch, .idle)
    }

    @MainActor
    func testRequestAIResearchFallsBackToPlaceholderWithNoOpProvider() async throws {
        let repository = MockRepository(scenarioProvider: { .normal })
        let viewModel = StrategyViewModel(repository: repository, notifications: NotificationManager(), haptics: HapticsManager())
        await viewModel.loadTemplates()
        guard case .loaded(let templates) = viewModel.templates, let template = templates.first else {
            return XCTFail("演示数据应至少存在一个模板")
        }
        viewModel.selectTemplateForBacktest(template)
        await viewModel.runBacktest()
        guard case .loaded = viewModel.backtestResult else {
            return XCTFail("回测应成功产生结果")
        }

        await viewModel.requestAIResearch()
        guard case .failed = viewModel.aiResearch else {
            return XCTFail("默认 Provider 尚未接入 API，应展示占位说明而非伪造结果")
        }
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
