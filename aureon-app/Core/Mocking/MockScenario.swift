//
//  MockScenario.swift
//  aureon-app
//
//  演示场景开关：供「我的 → API 环境」在离线状态下切换 UI 状态，
//  用于验证空状态 / 错误 / 断线 / 风控拒绝等分支，无需真实后端。
//

import Foundation

enum MockScenario: String, CaseIterable, Identifiable, Hashable {
    case normal
    case empty
    case serviceError
    case offline
    case riskRejected

    var id: String { rawValue }

    var labelZh: String {
        switch self {
        case .normal: return "正常演示"
        case .empty: return "空状态"
        case .serviceError: return "服务失败"
        case .offline: return "断线降级"
        case .riskRejected: return "风控拒绝"
        }
    }
}
