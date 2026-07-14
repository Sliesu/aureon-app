//
//  PilotViewModel.swift
//  aureon-app
//
//  AI Pilot 域视图模型：会话生命周期、决策日志、持仓与挂单。
//

import Foundation
import Observation

@MainActor
@Observable
final class PilotViewModel {
    private let repository: DataRepository
    private let haptics: HapticsManager

    var sessions: LoadState<[AiPilotSession]> = .idle
    var holdings: LoadState<[PilotHolding]> = .idle
    var pendingOrders: LoadState<[PilotOrder]> = .idle
    var decisionsBySession: [String: LoadState<[AiPilotDecision]>] = [:]

    var draftName: String = "新建 Pilot 会话"
    var draftInstId: String = "BTC-USDT-SWAP"
    var draftAutoExecute: Bool = false
    var draftDecisionGapSeconds: Int = 900

    init(repository: DataRepository, haptics: HapticsManager) {
        self.repository = repository
        self.haptics = haptics
    }

    func loadAll() async {
        async let sessionsResult: Void = loadSessions()
        async let holdingsResult: Void = loadHoldings()
        async let pendingResult: Void = loadPendingOrders()
        _ = await (sessionsResult, holdingsResult, pendingResult)
    }

    func loadSessions() async {
        sessions = .loading
        do {
            let result = try await repository.fetchPilotSessions()
            sessions = result.isEmpty ? .empty : .loaded(result)
        } catch {
            sessions = .failed(error.localizedDescription)
        }
    }

    func loadHoldings() async {
        holdings = .loading
        do {
            let result = try await repository.fetchPilotHoldings()
            holdings = result.isEmpty ? .empty : .loaded(result)
        } catch {
            holdings = .failed(error.localizedDescription)
        }
    }

    func loadPendingOrders() async {
        pendingOrders = .loading
        do {
            let result = try await repository.fetchPilotPendingOrders()
            pendingOrders = result.isEmpty ? .empty : .loaded(result)
        } catch {
            pendingOrders = .failed(error.localizedDescription)
        }
    }

    func loadDecisions(sessionId: String) async {
        decisionsBySession[sessionId] = .loading
        do {
            let result = try await repository.fetchPilotDecisions(sessionId: sessionId)
            decisionsBySession[sessionId] = result.isEmpty ? .empty : .loaded(result)
        } catch {
            decisionsBySession[sessionId] = .failed(error.localizedDescription)
        }
    }

    func createSession(requireAuthorization: () async -> Bool) async {
        if draftAutoExecute {
            guard await requireAuthorization() else { return }
        }
        let session = AiPilotSession(
            id: UUID().uuidString,
            name: draftName,
            instId: draftInstId,
            instType: .swap,
            status: .draft,
            autoExecute: draftAutoExecute,
            decisionGapSeconds: draftDecisionGapSeconds,
            createdAt: .now,
            lastDecisionAt: nil
        )
        _ = try? await repository.createPilotSession(session)
        haptics.success()
        await loadSessions()
    }

    func setStatus(sessionId: String, status: PilotSessionStatus) async {
        _ = try? await repository.setPilotStatus(sessionId: sessionId, status: status)
        await loadSessions()
    }

    func cancelOrder(id: String) async {
        try? await repository.cancelPilotOrder(id: id)
        await loadPendingOrders()
    }
}
