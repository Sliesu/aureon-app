//
//  MockDataGenerators.swift
//  aureon-app
//
//  确定性伪随机行情/统计数据生成器，保证同一会话内数据稳定、可复现，
//  避免每次刷新出现跳变。算法与种子均为演示用途，不代表真实市场行为。
//

import Foundation

struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func nextDouble() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(1 << 53)
    }

    mutating func nextRange(_ range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextDouble() * (range.upperBound - range.lowerBound)
    }
}

enum MockMarketFactory {
    static let supportedInstruments: [String] = [
        "BTC-USDT", "ETH-USDT", "SOL-USDT", "OKB-USDT", "XRP-USDT", "TON-USDT"
    ]

    static func basePrice(for instId: String) -> Double {
        switch instId {
        case "BTC-USDT": return 64_820
        case "ETH-USDT": return 3_412
        case "SOL-USDT": return 148.6
        case "OKB-USDT": return 46.2
        case "XRP-USDT": return 0.612
        case "TON-USDT": return 6.84
        default: return 100
        }
    }

    static func candles(instId: String, bar: CandleInterval, limit: Int) -> [Candle] {
        var generator = SeededGenerator(seed: UInt64(instId.hashValue) ^ UInt64(bar.rawValue.hashValue))
        var price = basePrice(for: instId)
        let stepSeconds: TimeInterval = intervalSeconds(bar)
        let now = Date()
        var results: [Candle] = []
        for index in stride(from: limit - 1, through: 0, by: -1) {
            let drift = generator.nextRange(-0.006...0.0065)
            let open = price
            price = max(price * (1 + drift), 0.0001)
            let high = max(open, price) * (1 + generator.nextRange(0...0.004))
            let low = min(open, price) * (1 - generator.nextRange(0...0.004))
            let volume = generator.nextRange(120...980)
            let ts = now.addingTimeInterval(-Double(index) * stepSeconds)
            results.append(Candle(ts: ts, open: open, high: high, low: low, close: price, volume: volume))
        }
        return results
    }

    static func intervalSeconds(_ bar: CandleInterval) -> TimeInterval {
        switch bar {
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        case .oneHour: return 3_600
        case .fourHours: return 14_400
        case .oneDay: return 86_400
        }
    }

    static func ticker(instId: String, referencePrice: Double? = nil) -> TickerSnapshot {
        var generator = SeededGenerator(seed: UInt64(Date().timeIntervalSince1970 * 10) ^ UInt64(instId.hashValue))
        let base = referencePrice ?? basePrice(for: instId)
        let last = base * (1 + generator.nextRange(-0.0015...0.0015))
        let spread = last * 0.0004
        let openReference = base * (1 + generator.nextRange(-0.03...0.035))
        return TickerSnapshot(
            instId: instId,
            last: last,
            bid: last - spread,
            ask: last + spread,
            open24h: openReference,
            high24h: max(last, openReference) * 1.012,
            low24h: min(last, openReference) * 0.988,
            vol24h: generator.nextRange(12_000...96_000),
            ts: .now
        )
    }

    static func volatilityStrip() -> [VolatilityStripItem] {
        supportedInstruments.map { instId in
            var generator = SeededGenerator(seed: UInt64(instId.hashValue))
            return VolatilityStripItem(instId: instId, changePercent24h: generator.nextRange(-6...7))
        }
    }

    static func macro() -> MacroSnapshot {
        var generator = SeededGenerator(seed: 42)
        var history: [MacroPoint] = []
        var value = 2.31
        let now = Date()
        for index in stride(from: 29, through: 0, by: -1) {
            value = max(value * (1 + generator.nextRange(-0.02...0.022)), 0.5)
            history.append(MacroPoint(t: now.addingTimeInterval(-Double(index) * 86_400), value: value))
        }
        return MacroSnapshot(
            totalMarketCapUsd: value * 1_000_000_000_000,
            btcDominancePercent: 52.4,
            fearGreedIndex: 58,
            history: history
        )
    }

    static func headlines() -> [HeadlineItem] {
        let titles = [
            "OKX 上线新一批永续合约标的，流动性持续提升",
            "宏观数据公布后加密市场波动率短线上升",
            "链上数据显示大额地址持续吸筹 BTC",
            "以太坊 Layer2 生态月活跃地址创新高",
            "多家机构报告看好第四季度加密资产表现"
        ]
        let now = Date()
        return titles.enumerated().map { index, title in
            HeadlineItem(
                id: "headline-\(index)",
                title: title,
                source: index.isMultiple(of: 2) ? "链上晨报" : "OKX Insights",
                publishedAt: now.addingTimeInterval(-Double(index) * 3_600),
                url: "https://www.okx.com/learn"
            )
        }
    }

    static func marketIntel(instId: String) -> MarketIntelSnapshot {
        var generator = SeededGenerator(seed: UInt64(instId.hashValue) ^ 7)
        return MarketIntelSnapshot(
            instId: instId,
            summaryZh: "\(instId) 当前资金费率处于温和正值区间，主流交易所多空比接近均衡，短期清算集中在上方阻力附近。",
            longShortRatio: generator.nextRange(0.85...1.25),
            liquidations24hUsd: generator.nextRange(1_200_000...9_800_000),
            fundingRatePercent: generator.nextRange(-0.02...0.035)
        )
    }

    static func orderBook(instId: String) -> OrderBookSnapshot {
        var generator = SeededGenerator(seed: UInt64(instId.hashValue) ^ 99)
        let mid = basePrice(for: instId)
        let bids = (0..<10).map { index -> OrderBookLevel in
            let price = mid * (1 - Double(index + 1) * 0.0006)
            return OrderBookLevel(price: price, size: generator.nextRange(0.2...6.5))
        }
        let asks = (0..<10).map { index -> OrderBookLevel in
            let price = mid * (1 + Double(index + 1) * 0.0006)
            return OrderBookLevel(price: price, size: generator.nextRange(0.2...6.5))
        }
        return OrderBookSnapshot(instId: instId, bids: bids, asks: asks, ts: .now)
    }

    static func fundingRate(instId: String) -> FundingRateInfo {
        var generator = SeededGenerator(seed: UInt64(instId.hashValue) ^ 11)
        return FundingRateInfo(
            instId: instId,
            fundingRatePercent: generator.nextRange(-0.01...0.02),
            nextFundingAt: Date().addingTimeInterval(3600 * 4)
        )
    }
}

enum MockAccountFactory {
    static func balances() -> ([BalanceDetail], AccountSummary) {
        let details = [
            BalanceDetail(ccy: "USDT", availableBalance: 18_420.55, frozenBalance: 320.00, equityUsd: 18_740.55),
            BalanceDetail(ccy: "BTC", availableBalance: 0.482, frozenBalance: 0, equityUsd: 31_235.44),
            BalanceDetail(ccy: "ETH", availableBalance: 3.21, frozenBalance: 0.4, equityUsd: 12_324.32)
        ]
        let summary = AccountSummary(
            totalEquityUsd: details.reduce(0) { $0 + $1.equityUsd },
            totalAvailableUsd: 55_820.12,
            totalFrozenUsd: 320.00,
            unrealizedPnlUsd: 842.35
        )
        return (details, summary)
    }

    static func positions() -> [Position] {
        [
            Position(id: "pos-1", instId: "BTC-USDT-SWAP", instType: .swap, side: .long, quantity: 0.6, entryPrice: 63_100, markPrice: 64_820, leverage: 3, unrealizedPnlUsd: 1_032, marginUsd: 12_620),
            Position(id: "pos-2", instId: "ETH-USDT-SWAP", instType: .swap, side: .short, quantity: 2.4, entryPrice: 3_460, markPrice: 3_412, leverage: 2, unrealizedPnlUsd: 115.2, marginUsd: 4_152)
        ]
    }

    static func pendingOrders() -> [PendingOrder] {
        [
            PendingOrder(id: "po-1", instId: "BTC-USDT", instType: .spot, side: .buy, price: 63_400, size: 0.05, filledSize: 0, createdAt: Date().addingTimeInterval(-1_800))
        ]
    }

    static func orders() -> [OrderRecord] {
        (0..<12).map { index -> OrderRecord in
            let isBitcoin = index.isMultiple(of: 2)
            let size = 0.02 + Double(index % 4) * 0.01
            return OrderRecord(
                id: "order-\(index)",
                instId: isBitcoin ? "BTC-USDT" : "ETH-USDT",
                instType: .spot,
                side: index.isMultiple(of: 3) ? .sell : .buy,
                price: isBitcoin ? 63_900 + Double(index) * 12 : 3_390 + Double(index) * 4,
                size: size,
                filledSize: size,
                state: index.isMultiple(of: 5) ? .canceled : .filled,
                createdAt: Date().addingTimeInterval(-Double(index) * 3_600)
            )
        }
    }

    static func fills() -> [FillRecord] {
        (0..<10).map { index -> FillRecord in
            let isBitcoin = index.isMultiple(of: 2)
            return FillRecord(
                id: "fill-\(index)",
                instId: isBitcoin ? "BTC-USDT" : "SOL-USDT",
                side: index.isMultiple(of: 3) ? .sell : .buy,
                price: isBitcoin ? 64_120 + Double(index) * 8 : 149.2 + Double(index) * 0.3,
                size: 0.01 + Double(index % 3) * 0.02,
                feeUsd: 0.42 + Double(index) * 0.03,
                filledAt: Date().addingTimeInterval(-Double(index) * 2_700)
            )
        }
    }

    static func bills() -> [BillRecord] {
        (0..<14).map { index in
            let types: [BillType] = [.trade, .funding, .transfer, .fee]
            return BillRecord(
                id: "bill-\(index)",
                ccy: "USDT",
                type: types[index % types.count],
                amount: index.isMultiple(of: 2) ? 120.4 : -45.2,
                balanceAfter: 18_000 + Double(index) * 32,
                occurredAt: Date().addingTimeInterval(-Double(index) * 5_400)
            )
        }
    }
}
