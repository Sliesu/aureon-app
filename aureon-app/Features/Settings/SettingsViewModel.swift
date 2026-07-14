//
//  SettingsViewModel.swift
//  aureon-app
//
//  我的域视图模型：交易/自动化模式、风控限额、显示偏好、API 环境、版本信息。
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let repository: DataRepository

    var payload: LoadState<SettingsPayload> = .idle
    var releaseNotes: LoadState<[ReleaseNote]> = .idle

    /// 可编辑的本地副本：风控与显示偏好在用户点击「保存」前只改变本地状态，
    /// 避免 Slider/Stepper 因绑定到只读快照而无法拖动。
    var editableRiskLimits: RiskLimits = .default
    var editableDisplayPrefs: DisplayPreferences = .default

    init(repository: DataRepository) {
        self.repository = repository
    }

    func loadAll() async {
        payload = .loading
        do {
            let result = try await repository.fetchSettings()
            payload = .loaded(result)
            editableRiskLimits = result.riskLimits
            editableDisplayPrefs = result.displayPrefs
        } catch {
            payload = .failed(error.localizedDescription)
        }
        do {
            let notes = try await repository.fetchReleaseNotes()
            releaseNotes = notes.isEmpty ? .empty : .loaded(notes)
        } catch {
            releaseNotes = .failed(error.localizedDescription)
        }
    }

    func updateScope(_ scope: WorkspaceScope) async {
        if let updated = try? await repository.updateScope(scope) { payload = .loaded(updated) }
    }

    func commitRiskLimits() async {
        if let updated = try? await repository.updateRiskLimits(editableRiskLimits) { payload = .loaded(updated) }
    }

    func commitDisplayPrefs() async {
        if let updated = try? await repository.updateDisplayPrefs(editableDisplayPrefs) { payload = .loaded(updated) }
    }
}
