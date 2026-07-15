//
//  BacktestAIResearchProvider.swift
//  aureon-app
//
//  回测结果的 AI 研判：针对一次回测生成买卖点解读、风险提示与优化建议。
//  当前仓库未接入真实 LLM 后端，`NoOpBacktestAIResearchProvider` 始终抛出
//  `.notConfigured`；UI 层据此展示「即将上线」占位而非伪造内容。
//  真实接入时只需实现 `BacktestAIResearchProviding` 并在 `AppEnvironment` /
//  `StrategyViewModel` 中替换默认实现，调用链路（按钮 → ViewModel → Provider）无需改动。
//

import Foundation

struct BacktestAIResearch: Equatable, Sendable {
    var summaryZh: String
    var riskNotesZh: [String]
    var suggestionsZh: [String]
    var generatedAt: Date
}

protocol BacktestAIResearchProviding: Sendable {
    func generateResearch(for result: BacktestResult) async throws -> BacktestAIResearch
}

struct NoOpBacktestAIResearchProvider: BacktestAIResearchProviding {
    func generateResearch(for result: BacktestResult) async throws -> BacktestAIResearch {
        throw NetworkError.notConfigured
    }
}
