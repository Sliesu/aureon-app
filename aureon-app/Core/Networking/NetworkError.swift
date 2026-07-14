//
//  NetworkError.swift
//  aureon-app
//

import Foundation

enum NetworkError: LocalizedError, Equatable {
    case offline
    case timeout
    case decodingFailed(String)
    case server(APIErrorEnvelope)
    case notConfigured
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .offline: return "网络连接不可用，已切换为缓存数据"
        case .timeout: return "请求超时，请稍后重试"
        case .decodingFailed(let detail): return "数据解析失败：\(detail)"
        case .server(let envelope): return envelope.message
        case .notConfigured: return "当前数据源尚未配置真实后端"
        case .unknown(let message): return message
        }
    }
}
