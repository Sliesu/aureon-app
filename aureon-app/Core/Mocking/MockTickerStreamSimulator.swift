//
//  MockTickerStreamSimulator.swift
//  aureon-app
//
//  本地模拟 SSE `/api/market/stream`：以 AsyncStream 定时推送 tick，
//  并在断线场景下演示「实时 → 轮询 → 离线」的降级路径。
//

import Foundation

enum MockTickerStreamSimulator {
    static func stream(instId: String, scenarioProvider: @escaping @Sendable () -> MockScenario) -> AsyncStream<MarketStreamEvent> {
        AsyncStream { continuation in
            let task = Task {
                if scenarioProvider() == .offline {
                    continuation.yield(.error("网络不可用"))
                    continuation.yield(.disconnected)
                    continuation.finish()
                    return
                }
                continuation.yield(.connected)
                var reference = MockMarketFactory.basePrice(for: instId)
                while !Task.isCancelled {
                    if scenarioProvider() == .serviceError {
                        continuation.yield(.error("演示场景：行情流服务异常"))
                        continuation.yield(.disconnected)
                        break
                    }
                    let tick = MockMarketFactory.ticker(instId: instId, referencePrice: reference)
                    reference = tick.last
                    continuation.yield(.tick(tick))
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
