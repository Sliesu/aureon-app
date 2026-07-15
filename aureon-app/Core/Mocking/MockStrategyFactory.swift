//
//  MockStrategyFactory.swift
//  aureon-app
//
//  策略模板、预设、运行与回测的确定性演示数据。
//

import Foundation

enum MockStrategyFactory {
    static func presets() -> [StrategyPreset] {
        StrategyStyle.allCases.map { style in
            StrategyPreset(id: "preset-\(style.rawValue)", name: style.titleZh, style: style, descriptionZh: style.descriptionZh)
        }
    }

    static func defaultTemplates() -> [StrategyTemplate] {
        let now = Date()
        return [
            makeTemplate(id: "tpl-1", name: "BTC 稳健定投", style: .conservative, instId: "BTC-USDT", instType: .spot, now: now),
            makeTemplate(id: "tpl-2", name: "ETH 双均线趋势", style: .dualMa, instId: "ETH-USDT-SWAP", instType: .swap, now: now),
            makeTemplate(id: "tpl-3", name: "SOL 网格突破", style: .gridBreakout, instId: "SOL-USDT", instType: .spot, now: now),
            makeTemplate(id: "tpl-4", name: "BTC 剥头皮实验", style: .scalper, instId: "BTC-USDT-SWAP", instType: .swap, now: now)
        ]
    }

    private static func makeTemplate(id: String, name: String, style: StrategyStyle, instId: String, instType: InstrumentType, now: Date) -> StrategyTemplate {
        StrategyTemplate(
            id: id,
            name: name,
            style: style,
            instId: instId,
            instType: instType,
            frequency: StrategyFrequency(kind: .interval, intervalSeconds: 300, cronExpression: nil),
            entrySizing: EntrySizing(usdAmount: 500, percentOfEquity: nil),
            leverage: instType == .swap ? 3 : 1,
            risk: RiskConfig(takeProfitPercent: 6, stopLossPercent: 3, maxLeverage: 5),
            ruleParams: ["fastMa": 7, "slowMa": 25, "rsiPeriod": 14],
            createdAt: now.addingTimeInterval(-86_400 * 6),
            updatedAt: now.addingTimeInterval(-3_600),
            lastBacktestSummary: BacktestSummary(
                totalReturnPercent: 18.4,
                winRatePercent: 57.2,
                maxDrawdownPercent: 9.1,
                sharpeRatio: 1.32,
                tradeCount: 46,
                completedAt: now.addingTimeInterval(-7_200)
            )
        )
    }

    static func defaultRuns() -> [TemplateRun] {
        let now = Date()
        return [
            TemplateRun(id: "run-1", templateId: "tpl-1", templateName: "BTC 稳健定投", style: .conservative, instId: "BTC-USDT", status: .running, startedAt: now.addingTimeInterval(-3_600 * 5), nextFireAt: now.addingTimeInterval(180), execFailStreak: 0, lastTickAt: now.addingTimeInterval(-60), realizedPnlUsd: 214.6),
            TemplateRun(id: "run-2", templateId: "tpl-2", templateName: "ETH 双均线趋势", style: .dualMa, instId: "ETH-USDT-SWAP", status: .paused, startedAt: now.addingTimeInterval(-3_600 * 20), nextFireAt: nil, execFailStreak: 1, lastTickAt: now.addingTimeInterval(-1_800), realizedPnlUsd: -42.1),
            TemplateRun(id: "run-3", templateId: "tpl-4", templateName: "BTC 剥头皮实验", style: .scalper, instId: "BTC-USDT-SWAP", status: .stopped, startedAt: now.addingTimeInterval(-3_600 * 40), nextFireAt: nil, execFailStreak: 0, lastTickAt: now.addingTimeInterval(-3_600 * 3), realizedPnlUsd: 58.9)
        ]
    }

    static func runOrders(runId: String) -> [TemplateOrderRow] {
        (0..<6).map { index in
            TemplateOrderRow(
                id: "\(runId)-order-\(index)",
                runId: runId,
                side: index.isMultiple(of: 2) ? .buy : .sell,
                price: 63_500 + Double(index) * 45,
                size: 0.01 + Double(index % 3) * 0.005,
                createdAt: Date().addingTimeInterval(-Double(index) * 1_200)
            )
        }
    }

    static func runTicks(runId: String) -> [TemplateRunTick] {
        let messages = [
            "评估信号：均线金叉，开仓条件满足",
            "风控检查通过，执行买入",
            "价格接近止盈位，观察中",
            "触发止盈，平仓获利",
            "信号中性，本轮观望"
        ]
        return messages.enumerated().map { index, message in
            TemplateRunTick(
                id: "\(runId)-tick-\(index)",
                runId: runId,
                occurredAt: Date().addingTimeInterval(-Double(index) * 900),
                messageZh: message,
                signal: index.isMultiple(of: 2) ? .buy : .hold
            )
        }
    }
}

enum MockBacktestFactory {
    static func run(_ request: BacktestRequest) -> BacktestResult {
        let candles = MockMarketFactory.candles(instId: request.instId, bar: request.bar, limit: request.limit)
        let seed = SeededGenerator.seedBits(from: request.instId.hashValue)
            ^ SeededGenerator.seedBits(from: request.style.hashValue)
        var generator = SeededGenerator(seed: seed)
        var equity = 10_000.0
        var equityCurve: [EquityPoint] = []
        var trades: [TradeRecord] = []
        var peak = equity

        for (index, candle) in candles.enumerated() where index % 6 == 0 {
            let pnlPercent = generator.nextRange(-2.4...3.1)
            equity *= (1 + pnlPercent / 100)
            peak = max(peak, equity)
            equityCurve.append(EquityPoint(t: candle.ts, equity: equity))
            if index % 12 == 0, index > 0 {
                let side: OrderSide = pnlPercent >= 0 ? .buy : .sell
                trades.append(TradeRecord(
                    id: "trade-\(index)",
                    entryAt: candles[max(0, index - 6)].ts,
                    exitAt: candle.ts,
                    side: side,
                    entryPrice: candles[max(0, index - 6)].close,
                    exitPrice: candle.close,
                    pnlPercent: pnlPercent,
                    isWin: pnlPercent >= 0
                ))
            }
        }

        let maxDrawdown = equityCurve.reduce((peak: equity, maxDD: 0.0)) { acc, point in
            let peak = max(acc.peak, point.equity)
            let drawdown = (peak - point.equity) / peak * 100
            return (peak, max(acc.maxDD, drawdown))
        }.maxDD

        let winCount = trades.filter(\.isWin).count
        let summary = BacktestSummary(
            totalReturnPercent: (equity - 10_000) / 10_000 * 100,
            winRatePercent: trades.isEmpty ? 0 : Double(winCount) / Double(trades.count) * 100,
            maxDrawdownPercent: maxDrawdown,
            sharpeRatio: generator.nextRange(0.6...1.9),
            tradeCount: trades.count,
            completedAt: .now
        )

        return BacktestResult(request: request, summary: summary, equityCurve: equityCurve, trades: trades, candles: candles)
    }

    static func walkForward(_ request: BacktestRequest) -> WalkForwardResult {
        var generator = SeededGenerator(
            seed: SeededGenerator.seedBits(from: request.instId.hashValue) ^ 0xABCD
        )
        let windows = (0..<5).map { index -> WalkForwardWindowResult in
            WalkForwardWindowResult(
                id: "window-\(index)",
                windowLabel: "窗口 \(index + 1)",
                inSampleReturnPercent: generator.nextRange(2...14),
                outSampleReturnPercent: generator.nextRange(-4...9)
            )
        }
        let average = windows.reduce(0) { $0 + $1.outSampleReturnPercent } / Double(windows.count)
        return WalkForwardResult(windows: windows, averageOutSampleReturnPercent: average)
    }

    static func paramScan(_ request: BacktestRequest) -> ParamScanResult {
        var generator = SeededGenerator(
            seed: SeededGenerator.seedBits(from: request.instId.hashValue) ^ 0x5151
        )
        let points = (0..<9).map { index -> ParamScanPoint in
            ParamScanPoint(
                id: "scan-\(index)",
                paramLabel: "fastMa=\(5 + index), slowMa=\(20 + index * 2)",
                totalReturnPercent: generator.nextRange(-6...24),
                maxDrawdownPercent: generator.nextRange(3...18)
            )
        }
        let best = points.max(by: { $0.totalReturnPercent < $1.totalReturnPercent })
        return ParamScanResult(points: points, bestPointId: best?.id)
    }
}

enum MockPilotFactory {
    static func sessions() -> [AiPilotSession] {
        [
            AiPilotSession(id: "pilot-1", name: "BTC 智能巡航", instId: "BTC-USDT-SWAP", instType: .swap, status: .running, autoExecute: false, decisionGapSeconds: 900, createdAt: Date().addingTimeInterval(-86_400 * 2), lastDecisionAt: Date().addingTimeInterval(-600))
        ]
    }

    static func decisions(sessionId: String) -> [AiPilotDecision] {
        let reasons = [
            "近期资金费率回落，多空比趋于均衡，判断短线维持观望",
            "4 小时均线多头排列，量能配合，给予小仓位买入建议",
            "价格触及区间上沿且 RSI 超买，建议部分止盈"
        ]
        return reasons.enumerated().map { index, reason in
            AiPilotDecision(
                id: "\(sessionId)-decision-\(index)",
                sessionId: sessionId,
                action: [.hold, .buy, .sell][index % 3],
                confidencePercent: [54, 71, 66][index % 3],
                reasoningZh: reason,
                executed: index == 1,
                occurredAt: Date().addingTimeInterval(-Double(index) * 1_800)
            )
        }
    }

    static func holdings() -> [PilotHolding] {
        [PilotHolding(id: "holding-1", instId: "BTC-USDT-SWAP", quantity: 0.2, averagePrice: 63_800, markPrice: 64_820, unrealizedPnlUsd: 204)]
    }

    static func pendingOrders() -> [PilotOrder] {
        [PilotOrder(id: "pilot-order-1", instId: "BTC-USDT-SWAP", side: .buy, price: 63_200, size: 0.05, createdAt: Date().addingTimeInterval(-900))]
    }
}

enum MockAdviceFactory {
    static func history() -> [AdviceRecord] {
        let now = Date()
        return [
            AdviceRecord(id: "advice-1", instId: "BTC-USDT", action: .buy, confidencePercent: 68, riskFlags: [AdviceRiskFlag(id: "f1", labelZh: "波动率偏高")], llmSummaryZh: "短期均线走强，资金流入放量，建议轻仓试多并设置止损。", createdAt: now.addingTimeInterval(-1_800)),
            AdviceRecord(id: "advice-2", instId: "ETH-USDT", action: .hold, confidencePercent: 52, riskFlags: [], llmSummaryZh: "价格处于区间中部，暂无明确方向信号，建议观望。", createdAt: now.addingTimeInterval(-7_200)),
            AdviceRecord(id: "advice-3", instId: "SOL-USDT", action: .sell, confidencePercent: 61, riskFlags: [AdviceRiskFlag(id: "f2", labelZh: "临近阻力位")], llmSummaryZh: "已触及关键阻力且量能萎缩，短线存在回调风险。", createdAt: now.addingTimeInterval(-14_400))
        ]
    }

    static func auditEvents() -> [AuditEvent] {
        let now = Date()
        let entries: [(AuditEventKind, String)] = [
            (.order, "BTC-USDT 市价买入 0.05，已成交"),
            (.risk, "单笔订单名义金额校验通过"),
            (.strategy, "策略「BTC 稳健定投」触发买入信号"),
            (.settings, "风控上限已更新：单笔订单上限调整为 500 USD")
        ]
        return entries.enumerated().map { index, entry in
            AuditEvent(id: "audit-\(index)", kind: entry.0, messageZh: entry.1, occurredAt: now.addingTimeInterval(-Double(index) * 2_400))
        }
    }
}
