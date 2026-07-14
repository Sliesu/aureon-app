//
//  AdviceModels.swift
//  aureon-app
//
//  洞察域模型：AI/规则建议、审计事件。准确率 metrics 为演示占位，非真实统计。
//

import Foundation

struct AdviceRiskFlag: Codable, Equatable, Identifiable {
    var id: String
    var labelZh: String
}

struct AdviceRecord: Codable, Equatable, Identifiable {
    var id: String
    var instId: String
    var action: AdviceAction
    var confidencePercent: Double
    var riskFlags: [AdviceRiskFlag]
    var llmSummaryZh: String?
    var createdAt: Date
}

/// 对齐 Web 版 `buildEvaluationStub()`：sampleSize=0，明确标注为占位统计。
struct AdviceEvaluationMetrics: Codable, Equatable {
    var sampleSize: Int
    var isPlaceholder: Bool
    var accuracyPercent: Double?

    static let placeholder = AdviceEvaluationMetrics(sampleSize: 0, isPlaceholder: true, accuracyPercent: nil)
}

enum AuditEventKind: String, Codable, Hashable {
    case order
    case risk
    case strategy
    case settings

    var labelZh: String {
        switch self {
        case .order: return "订单"
        case .risk: return "风控"
        case .strategy: return "策略"
        case .settings: return "设置"
        }
    }
}

struct AuditEvent: Codable, Equatable, Identifiable {
    var id: String
    var kind: AuditEventKind
    var messageZh: String
    var occurredAt: Date
}
