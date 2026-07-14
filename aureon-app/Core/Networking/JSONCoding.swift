//
//  JSONCoding.swift
//  aureon-app
//
//  共享的 Codable 编解码器，统一 ISO 8601 日期策略，与 Docs/openapi.yaml 保持一致。
//

import Foundation

enum AureonJSON {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = ISO8601DateFormatter.aureonFractional.date(from: raw) {
                return date
            }
            if let date = ISO8601DateFormatter.aureonStandard.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "无法解析日期：\(raw)")
        }
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISO8601DateFormatter.aureonFractional.string(from: date))
        }
        return encoder
    }()
}

extension ISO8601DateFormatter {
    static let aureonFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let aureonStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
