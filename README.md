# AUREON — 原生 iOS 量化工作台

AUREON 是 `okx-ai-quant-platform`（Web 版 OKX AI 量化平台）的原生 iOS
再实现：保留自选行情、K 线图表、策略模板、回测/纸面运行、AI Pilot、洞察建议
等核心能力，采用**乌木金纹（Ebony & Gold Grain）**视觉语言，并加入 Face
ID/Touch ID、触感反馈、本地通知、桌面小组件、灵动岛（Live Activity）与桌面
长按快捷操作（Quick Actions）等完整原生能力。

> 本仓库**只包含 iOS 客户端**，不实现服务端。所有数据默认来自本地
> `MockRepository`，可完整离线演示；真实后端契约见 [`Docs/openapi.yaml`](Docs/openapi.yaml)
> 与 [`Docs/API.md`](Docs/API.md)。

## 项目结构

```
aureon-app.xcodeproj/         主工程（含 aureon-app / AureonWidgets 两个原生 Target）
AureonShared/                 本地 Swift Package：主 App 与 Widget Extension 共享的
                               最小模型（深链路由、Live Activity 属性、App Group 快照）
AureonWidgets/                Widget Extension Target 源码：两个桌面小组件 + 策略
                               Live Activity（灵动岛/锁屏），Info.plist、entitlements
aureon-app/
  App/                        应用入口、AppDelegate/SceneDelegate 桥接、AppRouter、
                               全局环境容器、根视图 + Tab 切换、快捷操作注册
  Core/
    DesignSystem/              乌木金纹色板、字体、玻璃容器、通用组件
    Models/                    跨域共享 Codable 模型
    Networking/                DataRepository 协议、LiveAPIClient、SSE、错误模型
    Mocking/                   MockRepository 与确定性演示数据生成器
    Utilities/                 格式化、触感、生物认证、本地通知、APNs token 预留
                               接口、草稿存储
    LiveActivity/              Live Activity 生命周期管理（主 App 侧）
  Features/
    Market/                    市场：自选、实时报价、K 线/指标/回放、AI 摘要、模拟下单
    Account/                   账户：资产、持仓、委托、成交、流水
    Strategy/                  策略：模板编辑器、回测/Walk-forward/参数扫描、运行、AI Pilot
    Insights/                  洞察：AI/规则建议、宏观、新闻、订单簿、审计时间线
    Settings/                  我的：产品范围、风控、显示偏好、通知状态、API 环境、关于
aureon-appTests/              单元测试（含路由/深链/快照单测）
aureon-appUITests/            UI 测试
Docs/
  openapi.yaml                 完整 OpenAPI 3.1 客户端契约
  API.md                       端点 → Swift Repository 映射、Mock/Live 切换、演示场景
```

## 技术要点

- **SwiftUI + Observation**：`@Observable` ViewModel，`Bindable(...)` 用于
  跨层双向绑定；`SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` + 显式 `@MainActor`
  简化并发标注。
- **Feature-first MVVM + Repository**：`DataRepository` 协议统一 Mock/Live，
  ViewModel 完全不感知底层数据来源。
- **Swift Charts**：原生蜡烛图（Rule + Rectangle Mark）、EMA/RSI 叠加、
  权益曲线、迷你走势图；均无第三方图表依赖。
- **原生能力**：
  - LocalAuthentication（模拟下单/启用自动执行前二次确认）、Haptics、
    ShareLink（回测摘要分享）、pull-to-refresh、context menu。
  - **本地通知**（`Core/Utilities/NotificationManager.swift`）：策略状态
    变化、回测完成、风控拒绝三类事件的本地通知，点击后通过统一深链跳转到
    对应页面；在「我的 → 通知」中按需请求授权、发测试通知、跳转系统设置。
  - **APNs 预留接口**（`Core/Utilities/PushTokenRegistrar.swift`）：授权
    通过后会调用 `registerForRemoteNotifications()`，`AppDelegate` 接收
    device token / 失败回调并转发给 `PushTokenRegistering` 协议，默认
    `NoOpPushTokenRegistrar` 仅记录不上报；接入真实推送后端时替换该实现即可。
  - **统一原生入口路由**（`App/AppRouter.swift` + `AureonShared/DeepLink.swift`）：
    桌面快捷操作、桌面小组件/灵动岛点击、通知点击均编码为 `aureon://` 深链，
    由 `RootView` 统一解析并切换 Tab/子路由。
  - **桌面长按快捷操作**（`App/AureonQuickActionRegistrar.swift`）：市场行情、
    运行中策略、新建策略、通知设置四个入口，冷/热启动均可响应
    （`AppDelegate` + `AureonSceneDelegate`）。
  - **桌面小组件 + 灵动岛**（`AureonWidgets/` Target）：「自选行情」与
    「策略摘要」两个 Small/Medium 小组件，以及策略运行/回测的 Live Activity
    （锁屏卡片 + 灵动岛 expanded/compact/minimal 三态）。数据通过 App Group
    共享 `UserDefaults`（`AureonShared/WidgetSnapshotStore.swift`）在主 App
    写入、Widget Extension 读取，主 App 数据变化后调用 `WidgetCenter
    .reloadTimelines(ofKind:)` 请求刷新。

## 构建与运行

1. 使用 Xcode 16.x / 26.x 打开 `aureon-app.xcodeproj`（首次打开会自动解析本地
   Swift Package `AureonShared`，无需额外操作）。
2. 选择 `aureon-app` Scheme，运行在 iOS 18+ 模拟器或真机。
3. 默认数据源为 Mock，无需任何网络配置或密钥即可完整体验全部功能。
4. 如需体验不同 UI 状态，可在「我的 → API 环境 → 演示场景」切换空状态 /
   服务失败 / 断线降级 / 风控拒绝。

### 真机验收 App Group / 推送能力

仓库已包含 `aureon-app/aureon-app.entitlements`（App Group + Push
Notifications）与 `AureonWidgets/AureonWidgets.entitlements`（App Group），
均使用 `CODE_SIGN_STYLE = Automatic`。**首次在真机上运行/签名**时，请确保：

1. 用登录了付费或免费 Apple ID 的账号在 Xcode「Signing & Capabilities」中
   选择你自己的 Team（当前仓库预置的 `DEVELOPMENT_TEAM` 与
   Bundle Identifier `com.rbc.aureon-app` 均需替换为你自己的标识符与
   App Group（如 `group.<你的域名或标识>`），否则自动签名会失败。
2. 替换后，Xcode 会在首次构建时自动向 Developer Portal 注册 App ID / App
   Group / Push Notifications 能力（需要网络与已登录账号）。
3. 模拟器构建默认使用 `CODE_SIGNING_ALLOWED=NO`，不受上述限制，可直接验证
   UI、路由、通知本地展示与小组件占位内容；**灵动岛/锁屏 Live Activity 与
   桌面小组件的真实系统渲染建议在真机或 iOS 17+ 模拟器中肉眼验收**。

### 手工验收清单

- 长按主屏幕图标 → 应出现「市场行情 / 运行中策略 / 新建策略 / 通知设置」
  四个快捷项，点击后冷启动/热启动均应直达对应页面。
- 「我的 → 通知」→ 开启通知 → 发送测试通知 → 点击通知横幅应跳转回通知设置页。
- 策略 Tab 启动一个运行 / 触发一次回测 → 锁屏与灵动岛应出现对应 Live
  Activity，结束后按预期消失。
- 长按桌面添加「AUREON 自选」「AUREON 策略摘要」两个小组件 → 应显示本地
  Mock 数据，点击行 / 小组件应直达市场或运行列表页。

## 已知限制

- **无服务端 Live Activity 更新**：当前没有真实推送后端，Live Activity 的
  进度/盈亏只能依赖主 App 在前台或短暂后台期间调用
  `LiveActivityManager` 主动更新；App 长时间挂起后不会持续获得实时数据，
  这是「仅本地通知 + 预留 APNs 接口」架构下的预期行为。
- **APNs 尚未真正投递远程推送**：`PushTokenRegistrar` 只负责把 device
  token 转发给可替换的 `PushTokenRegistering` 实现（默认 no-op）；要真正
  收到远程推送，需要先落地服务端设备注册 + APNs 网关（契约占位见
  `Docs/API.md`），本仓库范围内不包含该服务端实现。
- **App Group / Push 能力需替换为你自己的标识符**：见上文「真机验收」一节。

## 免责声明

所有交易、策略运行与 AI 建议均为本地演示，不构成投资建议，也不会产生真实
资金操作。
