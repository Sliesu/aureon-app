# AUREON — 原生 iOS 量化工作台

AUREON 是 `okx-ai-quant-platform`（Web 版 OKX AI 量化平台）的原生 iOS
再实现：保留自选行情、K 线图表、策略模板、回测/纸面运行、AI Pilot、洞察建议
等核心能力，采用**乌木金纹（Ebony & Gold Grain）**视觉语言与自适应
**液态玻璃（Liquid Glass）**底部 Dock，并加入 Face ID/Touch ID、触感反馈、
本地通知、Widget 与 Live Activity 等原生能力。

> 本仓库**只包含 iOS 客户端**，不实现服务端。所有数据默认来自本地
> `MockRepository`，可完整离线演示；真实后端契约见 [`Docs/openapi.yaml`](Docs/openapi.yaml)
> 与 [`Docs/API.md`](Docs/API.md)。

## 项目结构

```
aureon-app/
  App/                     应用入口、全局环境容器、根视图 + Dock 挂载
  Core/
    DesignSystem/           乌木金纹色板、字体、玻璃容器、Dock、通用组件
    Models/                 跨域共享 Codable 模型
    Networking/              DataRepository 协议、LiveAPIClient、SSE、错误模型
    Mocking/                 MockRepository 与确定性演示数据生成器
    Utilities/                格式化、触感、生物认证、通知、草稿存储、Widget 快照
    LiveActivity/            Live Activity 属性与生命周期管理
  Features/
    Market/                  市场：自选、实时报价、K 线/指标/回放、AI 摘要、模拟下单
    Account/                 账户：资产、持仓、委托、成交、流水
    Strategy/                策略：模板编辑器、回测/Walk-forward/参数扫描、运行、AI Pilot
    Insights/                洞察：AI/规则建议、宏观、新闻、订单簿、审计时间线
    Settings/                我的：产品范围、风控、显示偏好、API 环境、关于
  Widgets/                   Widget/Live Activity 预制代码（见下方「已知限制」）
  Resources/                 资源目录（Assets 等）
aureon-appTests/            单元测试
aureon-appUITests/          UI 测试
Docs/
  openapi.yaml               完整 OpenAPI 3.1 客户端契约
  API.md                     端点 → Swift Repository 映射、Mock/Live 切换、演示场景
```

## 技术要点

- **SwiftUI + Observation**：`@Observable` ViewModel，`Bindable(...)` 用于
  跨层双向绑定；`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 简化并发标注。
- **Feature-first MVVM + Repository**：`DataRepository` 协议统一 Mock/Live，
  ViewModel 完全不感知底层数据来源。
- **Swift Charts**：原生蜡烛图（Rule + Rectangle Mark）、EMA/RSI 叠加、
  权益曲线、迷你走势图；均无第三方图表依赖。
- **自适应 Liquid Glass**：iOS 26+ 使用系统 `glassEffect` / `GlassEffectContainer`；
  iOS 18–25 降级为 `Material` + 金色描边，视觉语言保持一致（见
  `Core/DesignSystem/GlassSurface.swift`、`AureonLiquidGlassDock.swift`）。
- **原生能力**：LocalAuthentication（模拟下单/启用自动执行前二次确认）、
  Haptics（Dock 切换/下单成功/风控拒绝）、UserNotifications（策略状态/回测
  完成/风险提醒的本地通知）、ShareLink（回测摘要分享）、pull-to-refresh、
  context menu。

## 构建与运行

1. 使用 Xcode 16.x / 26.x 打开 `aureon-app.xcodeproj`。
2. 选择 `aureon-app` Scheme，运行在 iOS 18+ 模拟器或真机。
3. 默认数据源为 Mock，无需任何网络配置或密钥即可完整体验全部功能。
4. 如需体验不同 UI 状态，可在「我的 → API 环境 → 演示场景」切换空状态 /
   服务失败 / 断线降级 / 风控拒绝。

## 已知限制（云端环境交付说明）

本次实现在**没有 Xcode/完整 iOS SDK 的云端 Linux 环境**中完成：

- 已生成完整的 Xcode 工程（`project.pbxproj` 使用 Xcode 16+ 的
  `PBXFileSystemSynchronizedRootGroup`，新增/删除 `aureon-app/` 目录下的
  Swift 文件会被自动纳入编译，无需手工维护成员列表）。
- **无法在本环境执行 `xcodebuild`/`swift build` 校验编译**，已改用逐文件人工
  静态交叉校验替代：核对了单元测试 (`aureon-appTests`) 与 UI 测试
  (`aureon-appUITests`) 中用到的每个类型/初始化器/方法签名/属性/枚举 case
  是否与 `Core`、`Features` 下的实际声明完全一致；核对了所有在
  `ForEach(id: \.self)` / `Picker(selection:)` / `.tag()` 中使用的枚举均已
  声明 `Hashable`；确认已删除的 SwiftData 模板 `ContentView`/`Item` 无残留
  引用；确认工程内无重复类型声明；确认仅有一个 `@main` 入口
  (`App/AureonApp.swift`)。请在拥有完整 Xcode 的机器上打开工程完成首次
  构建，修复可能出现的少量收尾编译问题（例如某些 API 在特定 Xcode 版本下
  的可用性差异，或 iOS 26 SDK 独有符号在更旧 Xcode 上的缺失）。
- **Widget Extension / Live Activity UI**：`Widgets/AureonWidgetsPreview.swift`
  提供了完整的小组件与 Live Activity 预制 SwiftUI 代码（故意未标记 `@main`
  以避免与主 App 冲突），但创建实际的 Widget Extension Target（File → New →
  Target → Widget Extension）依赖 Xcode 项目模型的 GUI 操作，无法通过纯文本
  编辑 `project.pbxproj` 安全自动化，需要在本机 Xcode 中手动完成，步骤见该
  文件顶部注释。
- **App Group**（Widget 与主 App 共享数据）：`Core/Utilities/WidgetSnapshotStore.swift`
  当前使用 `UserDefaults.standard` 占位；若创建了 Widget Extension，需要在
  Xcode 中为两个 Target 开启 App Groups 能力并在开发者账号注册组标识符，
  然后将该文件中的 `UserDefaults.standard` 替换为
  `UserDefaults(suiteName: "group.xxx")`。

## 免责声明

所有交易、策略运行与 AI 建议均为本地演示，不构成投资建议，也不会产生真实
资金操作。
