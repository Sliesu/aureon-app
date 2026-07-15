# AUREON API 说明

本文档补充 [`openapi.yaml`](./openapi.yaml)，说明当前 iOS 客户端的数据来源、
端点到 Swift Repository 的映射，以及 Mock/Live 切换方式。

## 现状：本仓库只有客户端

`aureon-app` 是一个**独立的原生 iOS 项目**，不依赖、也不修改
`okx-ai-quant-platform`（Web 版）代码。当前仓库**未实现任何服务端**：

- 所有真实交易执行、策略调度、LLM 调用、回测计算与密钥管理，按计划保留在
  未来的后端服务中（可参考 Web 版 `okx-ai-quant-platform` 的现有实现思路）。
- iOS 客户端本身**不持有、不请求任何 OKX / LLM 密钥**。
- 默认数据源为 `MockRepository`（见 `Core/Mocking/MockRepository.swift`），
  100% 离线可运行、可演示。

## 端点 → Swift 映射

所有客户端数据访问都通过 `DataRepository` 协议
（`Core/Networking/DataRepository.swift`）完成，ViewModel 层不感知具体实现：

| 协议方法 | OpenAPI 端点 | 说明 |
|---|---|---|
| `fetchSettings` / `updateScope` / `updateRiskLimits` / `updateDisplayPrefs` | `GET/PATCH /api/settings` | 聚合设置，对齐 Web 版 `workspace-settings-contract.ts` |
| `fetchWatchlist` / `toggleWatchlist` | `GET/POST /api/watchlist` | 自选列表 |
| `fetchTicker` / `fetchCandles` / `fetchPriceSeries` | `GET /api/market/ticker /ohlcv /series` | 行情与 K 线 |
| `streamTicker` | `GET /api/market/stream` (SSE) | 实时行情，断线自动降级为轮询 |
| `fetchVolatilityStrip` / `fetchMacro` / `fetchHeadlines` / `fetchMarketIntel` | `GET /api/market/*` | 市场情报与宏观上下文 |
| `fetchOrderBook` / `fetchFundingRate` / `fetchInstruments` | `GET /api/market/orderbook /funding`, `/api/okx/instruments` | 订单簿、资金费率、标的列表 |
| `analyzeCandles` | `POST /api/ai/candles-analyze` | AI K 线摘要 |
| `fetchBalances` / `fetchPositions` / `fetchPendingOrders` / `fetchOrders` / `fetchFills` / `fetchBills` | `GET /api/account/*` | 账户域全部只读数据 |
| `placeOrder` | `POST /api/execute` | 模拟/实盘下单，受风控限额与自动化模式约束 |
| `fetchStrategyPresets` / `fetchTemplates` / `createTemplate` / `updateTemplate` / `deleteTemplate` | `/api/strategy/presets`, `/api/strategy/templates*` | 策略模板 CRUD |
| `fetchRuns` / `startRun` / `setRunStatus` / `fetchRunOrders` / `fetchRunTicks` | `/api/strategy/runs*` | 运行实例生命周期 |
| `runBacktest` / `runWalkForward` / `runParamScan` | `/api/strategy/backtest*` | 回测能力（标准 / Walk-forward / 参数扫描） |
| `fetchPilotSessions` / `createPilotSession` / `setPilotStatus` / `fetchPilotDecisions` / `fetchPilotHoldings` / `fetchPilotPendingOrders` / `cancelPilotOrder` | `/api/ai/pilot/*` | AI Pilot 自主决策会话 |
| `evaluateAdvice` / `fetchAdviceHistory` / `fetchEvaluationMetrics` / `fetchAuditEvents` | `/api/advice`, `/api/audit` | 建议与审计 |

## Mock ↔ Live 切换

在「我的 → API 环境」中：

1. 默认 **Mock**：使用 `MockRepository`，所有数据在本地生成，无网络依赖。
2. 切换为 **Live** 并填写 Base URL 后，`AppEnvironment.switchDataSource`
   会以 `LiveAPIClient`（`Core/Networking/LiveAPIClient.swift`）替换仓库实现。
   由于当前没有真实后端，未填写 Base URL 时会自动回退为 Mock，所有请求方法
   在 `baseURL == nil` 时均抛出 `NetworkError.notConfigured`，不会产生任何
   隐式网络访问。

`LiveAPIClient` 已经实现了完整的 URLSession 请求管线（`APIEndpoint.swift`
定义了所有路径），后端团队按 `openapi.yaml` 实现后即可直接对接，无需修改
客户端调用方代码。

## Mock 场景（用于演示 / QA）

在「我的 → API 环境 → 演示场景」中可切换以下场景（仅在数据源为 Mock 时生效，
定义见 `Core/Mocking/MockScenario.swift`）：

| 场景 | 行为 |
|---|---|
| 正常演示 | 默认行为，所有列表返回确定性演示数据 |
| 空状态 | 各列表返回空数组，用于验证 Empty State 文案与布局 |
| 服务失败 | 所有请求抛出 `server` 错误，用于验证 Error State 与重试按钮 |
| 断线降级 | 行情流直接标记为 `disconnected`，用于验证「实时 → 轮询 → 离线」的连接状态徽章 |
| 风控拒绝 | 下单请求始终返回 `order_notional_exceeded`，用于验证风控拒绝态横幅 |

## 未来推送服务端接入点（当前未实现）

客户端已预留 APNs 设备 token 注册接口（`Core/Utilities/PushTokenRegistrar.swift`
中的 `PushTokenRegistering` 协议，默认 `NoOpPushTokenRegistrar`），未来接入真实
推送后端时，建议的契约占位如下（尚未在 `openapi.yaml` 中定义，仅作为落地参考）：

```
POST /api/devices/push-token
{
  "deviceTokenHex": "string",
  "platform": "ios",
  "bundleId": "com.rbc.aureon-app",
  "environment": "development" | "production"
}
```

服务端落地后，只需实现该协议并在 `AppEnvironment`/`PushTokenRegistrarHolder`
中替换默认实现，客户端调用链路（授权 → `registerForRemoteNotifications()` →
`AppDelegate` 回调 → 协议转发）无需改动。

## 日期与错误格式

- 所有时间字段使用 ISO-8601（含小数秒），解码逻辑见 `Core/Networking/JSONCoding.swift`。
- 错误统一使用 `ErrorEnvelope { code, message, details? }`，`code` 取值见
  `Core/Models/CommonModels.swift` 中的 `RiskRejectionReason`。

## 免责声明

洞察域的建议准确率统计（`AdviceEvaluationMetrics`）当前为**占位数据**
（`sampleSize = 0`），UI 中会明确标注「演示占位数据」标签，不代表任何真实
策略表现或投资建议。
