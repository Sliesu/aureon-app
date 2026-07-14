//
//  AccountViewModel.swift
//  aureon-app
//
//  账户域视图模型：资产、持仓、委托、成交、流水，SPOT/SWAP 联动 tradingMode。
//

import Foundation
import Observation

@MainActor
@Observable
final class AccountViewModel {
    private let repository: DataRepository

    var selectedTab: AccountTab = .assets
    var instTypeFilter: InstrumentType = .spot

    var balances: LoadState<[BalanceDetail]> = .idle
    var summary: AccountSummary?
    var positions: LoadState<[Position]> = .idle
    var pendingOrders: LoadState<[PendingOrder]> = .idle
    var orders: LoadState<[OrderRecord]> = .idle
    var fills: LoadState<[FillRecord]> = .idle
    var bills: LoadState<[BillRecord]> = .idle

    init(repository: DataRepository) {
        self.repository = repository
    }

    func availableTabs(scope: WorkspaceScope) -> [AccountTab] {
        scope.tradingMode == .spot ? AccountTab.allCases.filter { $0 != .positions } : AccountTab.allCases
    }

    func loadCurrentTab() async {
        switch selectedTab {
        case .assets: await loadBalances()
        case .positions: await loadPositions()
        case .pending: await loadPendingOrders()
        case .orders: await loadOrders()
        case .fills: await loadFills()
        case .bills: await loadBills()
        }
    }

    func loadBalances() async {
        balances = .loading
        do {
            let (details, summaryResult) = try await repository.fetchBalances()
            summary = summaryResult
            balances = details.isEmpty ? .empty : .loaded(details)
        } catch {
            balances = .failed(error.localizedDescription)
        }
    }

    func loadPositions() async {
        positions = .loading
        do {
            let result = try await repository.fetchPositions(instType: nil)
            positions = result.isEmpty ? .empty : .loaded(result)
        } catch {
            positions = .failed(error.localizedDescription)
        }
    }

    func loadPendingOrders() async {
        pendingOrders = .loading
        do {
            let result = try await repository.fetchPendingOrders(instType: instTypeFilter)
            pendingOrders = result.isEmpty ? .empty : .loaded(result)
        } catch {
            pendingOrders = .failed(error.localizedDescription)
        }
    }

    func loadOrders() async {
        orders = .loading
        do {
            let result = try await repository.fetchOrders(instType: instTypeFilter)
            orders = result.isEmpty ? .empty : .loaded(result)
        } catch {
            orders = .failed(error.localizedDescription)
        }
    }

    func loadFills() async {
        fills = .loading
        do {
            let result = try await repository.fetchFills(instType: instTypeFilter)
            fills = result.isEmpty ? .empty : .loaded(result)
        } catch {
            fills = .failed(error.localizedDescription)
        }
    }

    func loadBills() async {
        bills = .loading
        do {
            let result = try await repository.fetchBills()
            bills = result.isEmpty ? .empty : .loaded(result)
        } catch {
            bills = .failed(error.localizedDescription)
        }
    }
}
