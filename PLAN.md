 # PLAN.md — 股票操作分析师 Agent(stockbuffett)

> Spec-Driven Development · 开发计划
> 依赖文档:[SPEC.md](./SPEC.md)
> 编写日期:2026-10-17

---

## 1. SDD 工作流

我们采用 4 阶段开发流程,**每个阶段都有可验证的产物**:

```
┌────────────┐    ┌────────────┐    ┌────────────┐    ┌────────────┐
│  1. SPEC   │ →  │ 2. DESIGN  │ →  │  3. CODE   │ →  │  4. TEST   │
│  (已完成)  │    │ (本次评审) │    │  (按迭代)  │    │  (验收)    │
└────────────┘    └────────────┘    └────────────┘    └────────────┘
   需求规格         详细设计         代码实现          测试验收
   SPEC.md         DESIGN.md       按 Milestone      AC-x
```

### 当前进度
- ✅ Stage 1 — SPEC(本文档 + SPEC.md 已完成,等待你 review)
- ⏳ Stage 2 — DESIGN(SPEC 通过后启动,产出 DESIGN.md)
- ⏳ Stage 3 — CODE(按 Milestone 1→6 迭代)
- ⏳ Stage 4 — TEST(每个 Milestone 收尾)

---

## 2. 技术栈

### 2.1 核心选型

| 维度 | 选型 | 理由 |
|---|---|---|
| 语言 | **Swift 5.9+** | iOS 原生 |
| UI | **SwiftUI** | 项目已用,声明式,易迭代 |
| 最低 iOS | **iOS 17.0** | 现代 SwiftUI 4 + NavigationStack 完善 |
| 数据存储 | **Foundation FileManager** + Codable | 简单、可读、零依赖 |
| 路径 API | **URL**(避免 String 拼接) | 安全处理特殊字符 |
| LLM 协议 | **Anthropic Messages API**(MiniMax 兼容) | 与官方一致 |
| LLM 实现 | **URLSession + SSE 流式** | 无第三方依赖 |
| 图片选择 | **PhotosUI(PhotosPicker)** | iOS 16+ 标准 |
| Markdown 渲染 | **SwiftUI `AttributedString(markdown:)`** | 系统级,零依赖 |
| API Key | **Keychain**(`Security` framework) | Apple 官方 |
| 备份压缩 | **iOS 15+ 内置 `Compression`** + 自封装 ZIP | 零依赖 |
| JSON | **Codable** | 标准库 |
| 日期处理 | **Foundation `Date` + `ISO8601DateFormatter`** | 标准库 |

### 2.2 第三方依赖
**零第三方依赖**。所有能力用系统 API 实现,降低维护成本。

### 2.3 API 关键参数

| 参数 | 值 |
|---|---|
| Endpoint | `https://api.minimax.io/anthropic/v1/messages` |
| Model | `MiniMax-M3` |
| Headers | `x-api-key: {Key}`, `anthropic-version: 2023-06-01`, `content-type: application/json` |
| max_tokens | 4096(操作建议) / 2048(截图解析) |
| stream | `true`(操作建议) / `false`(截图解析) |
| Vision 图片 | `type: "image"`, `source.type: "base64"`, `media_type: "image/jpeg"` |

---

## 3. 项目目录结构

```
stockbuffett/                                  ← Xcode project 根
├── stockbuffett.xcodeproj/
├── stockbuffett/                               ← 源码目录
│   │
│   ├── stockbuffettApp.swift                   ← App 入口
│   │
│   ├── App/
│   │   └── RootView.swift                      ← TabView 顶层
│   │
│   ├── Models/                                 ← 数据模型(Codable)
│   │   ├── Topic.swift
│   │   ├── Note.swift
│   │   ├── HoldingDay.swift
│   │   ├── Position.swift
│   │   ├── ChatSession.swift
│   │   ├── ChatMessage.swift
│   │   └── AdvisoryResponse.swift              ← M3 JSON 输出模型
│   │
│   ├── Services/                               ← 业务服务层
│   │   ├── FileStore.swift                     ← 文件存储(notes/holdings/chats)
│   │   ├── KeychainStore.swift                 ← API Key
│   │   ├── LLMClient.swift                     ← Messages API 封装(流式 + 非流式)
│   │   ├── PromptBuilder.swift                 ← 上下文拼装
│   │   ├── BackupService.swift                 ← 备份导出
│   │   └── HoldingsContextBuilder.swift        ← 持仓摘要生成
│   │
│   ├── Views/
│   │   ├── Notes/
│   │   │   ├── TopicsListView.swift
│   │   │   ├── NotesListView.swift
│   │   │   ├── NoteDetailView.swift
│   │   │   ├── NoteEditorView.swift
│   │   │   └── NewTopicSheet.swift
│   │   │
│   │   ├── Holdings/
│   │   │   ├── HoldingsView.swift
│   │   │   ├── HoldingsTable.swift             ← 子组件
│   │   │   ├── ImportPreviewView.swift
│   │   │   ├── EditPositionSheet.swift
│   │   │   └── NewDaySheet.swift
│   │   │
│   │   ├── Chat/
│   │   │   ├── ChatListView.swift
│   │   │   ├── ChatView.swift
│   │   │   ├── ChatInputBar.swift
│   │   │   ├── AdvisoryCard.swift              ← 渲染结构化建议
│   │   │   └── ActionCard.swift                ← 单个 action 卡片
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   └── AboutView.swift
│   │   │
│   │   └── Components/                         ← 通用组件
│   │       ├── EmptyStateView.swift
│   │       ├── LoadingOverlay.swift
│   │       └── ConfirmDialog.swift
│   │
│   ├── Resources/
│   │   ├── Prompts/
│   │   │   ├── system_prompt.txt               ← 主 Prompt
│   │   │   └── ocr_prompt.txt                  ← 截图解析 Prompt
│   │   └── Assets.xcassets/
│   │
│   ├── Extensions/
│   │   ├── Date+Format.swift
│   │   ├── String+Sanitize.swift               ← 文件名安全
│   │   └── URL+Sandbox.swift                   ← Documents/buffett 子路径
│   │
│   └── Utilities/
│       └── Logger.swift                        ← os_log 封装
│
├── stockbuffettTests/                          ← 单元测试
│   ├── FileStoreTests.swift
│   ├── PromptBuilderTests.swift
│   ├── HoldingsJSONTests.swift
│   └── AdvisoryResponseTests.swift
│
├── stockbuffettUITests/                        ← UI 测试(可选)
│
├── SPEC.md                                     ← 需求规格(已生成)
├── PLAN.md                                     ← 本文档
└── README.md                                   ← 用户使用说明(发布前补)
```

---

## 4. 开发里程碑(Milestones)

### 总览

| M# | 主题 | 工作量(预估) | 验收 |
|---|---|---|---|
| M1 | 工程脚手架 + 导航框架 | 1-2 天 | App 跑起来,Tab 切换正常 |
| M2 | 炒股心得模块 | 2-3 天 | AC-1 全过 |
| M3 | 持股模块 + 截图导入 | 3-4 天 | AC-2 全过 |
| M4 | 操作建议模块 + Prompt | 3-4 天 | AC-3 全过 |
| M5 | 设置 + 备份导出 | 1-2 天 | AC-4 全过 |
| M6 | 打磨 + 测试 | 1-2 天 | 全部 AC 过 |

**总计预估:11-17 个工作日**(单人开发,业余时间)

---

### Milestone 1:工程脚手架 + 导航框架

**目标**:App 能跑起来,三大模块 Tab 切换正常

**任务清单**:
- [ ] 创建 Xcode 项目目录结构(`Models/`, `Services/`, `Views/` 等)
- [ ] 把 `ContentView.swift` 改名为 `RootView.swift`,实现 TabView 骨架
- [ ] 三个 Tab 占位页:`TopicsListView`、`HoldingsView`、`ChatListView`(空内容)
- [ ] `URL+Sandbox.swift`:定义 `buffettRoot` 等沙盒子路径常量
- [ ] `FileStore.swift`:基础骨架(目录创建、读写 API)
- [ ] `KeychainStore.swift`:基础骨架
- [ ] 验证:真机/模拟器跑起来,切 Tab 无报错

**验收标准**:
- ✅ App 启动后显示 3 Tab(心得/持股/建议)+ 1 设置入口
- ✅ 沙盒 `Documents/buffett/{notes,holdings,chats,settings}/` 自动创建
- ✅ 没有运行时崩溃

---

### Milestone 2:炒股心得模块

**目标**:完整 CRUD 两层目录心得

**任务清单**:
- [ ] `Topic.swift`、`Note.swift` 数据模型(Codable)
- [ ] `FileStore` 扩展:notes 目录的增删改查
- [ ] `TopicsListView`:主题卡片列表 + `+` 按钮 + 滑动删除
- [ ] `NewTopicSheet`:新建/重命名主题
- [ ] `NotesListView`:主题下心得列表 + `+` 按钮 + 滑动删除
- [ ] `NoteDetailView`:查看(Markdown 渲染)
- [ ] `NoteEditorView`:编辑/新建 Markdown
- [ ] 错误处理:删除主题弹确认、级联删除提示

**验收标准**:
- ✅ AC-1 全部过
- ✅ 重启 App 数据保留
- ✅ Markdown 渲染正确(标题、列表、代码、链接)

---

### Milestone 3:持股模块 + 截图导入

**目标**:每日持仓 CRUD + Vision 截图导入端到端

**任务清单**:
- [ ] `HoldingDay.swift`、`Position.swift` 数据模型
- [ ] `FileStore` 扩展:holdings 目录按日期读写
- [ ] `HoldingsView`:默认今天 + DatePicker + 持仓表格 + 盈亏计算
- [ ] `NewDaySheet`:新建某天
- [ ] `EditPositionSheet`:单只股票增删改
- [ ] `PhotosPicker` 集成(选择截图)
- [ ] `LLMClient` 雏形:实现 `messages` 接口,封装 base URL、headers
- [ ] `ocr_prompt.txt`:截图解析专用 Prompt(返回 `positions` 数组 JSON)
- [ ] `ImportPreviewView`:左边原图 + 右边可编辑表格 + "保存到 {date}"
- [ ] 冲突处理:当天已有记录弹"覆盖/合并"

**验收标准**:
- ✅ AC-2 全部过
- ✅ 用同花顺实际截图跑通端到端
- ✅ OCR 不准的字段可手动修正后保存

---

### Milestone 4:操作建议模块 + Prompt 模板

**目标**:完整对话 + 流式 + 结构化渲染

**任务清单**:
- [ ] `ChatSession.swift`、`ChatMessage.swift`、`AdvisoryResponse.swift` 模型
- [ ] `PromptBuilder`:拼装系统 Prompt + 心得摘要 + 持仓 + 用户问题
- [ ] `LLMClient` 完整实现:
  - [ ] 流式响应(URLSession bytes / SSE 解析)
  - [ ] 取消生成(Task cancellation)
  - [ ] 错误处理(401/超时/网络)
- [ ] `HoldingsContextBuilder`:持仓 → 摘要字符串
- [ ] 心得摘要生成:近 30 天 + 高频引用(简化版)
- [ ] `ChatListView`:历史对话列表
- [ ] `ChatView`:对话详情 + 输入框 + 流式渲染
- [ ] `ChatInputBar`:文本 + 图片附件
- [ ] `AdvisoryCard` / `ActionCard`:结构化 JSON → 卡片 UI
- [ ] Fallback 处理:M3 返回非 JSON 时原始文本框展示

**验收标准**:
- ✅ AC-3 全部过
- ✅ 首字 < 2s(实测)
- ✅ 流式响应流畅,UI 不卡
- ✅ 对话历史正确持久化

---

### Milestone 5:设置 + 备份导出

**目标**:API Key 配置 + 备份导出可用

**任务清单**:
- [ ] `KeychainStore` 完整实现(CRUD API Key)
- [ ] `SettingsView`:
  - [ ] API Key 输入框 + "测试连接"按钮(发一个简单消息测试)
  - [ ] "导出备份"按钮
  - [ ] "清空数据"危险操作
  - [ ] 关于入口
- [ ] `BackupService`:
  - [ ] 遍历三个目录 → 写临时 ZIP → 调 `UIActivityViewController`
  - [ ] 文件名:`buffett-backup-{YYYYMMDD-HHmm}.zip`
  - [ ] 排除 `settings/config.json`
- [ ] `AboutView`:版本号 + 项目说明

**验收标准**:
- ✅ AC-4 全部过
- ✅ Key 存 Keychain,重启不丢
- ✅ 备份 ZIP 解压验证内容 + 无 Key
- ✅ 系统分享面板能弹出,微信/邮件可发送

---

### Milestone 6:打磨 + 测试

**目标**:稳定可用,可发 TestFlight

**任务清单**:
- [ ] 单元测试:
  - [ ] `FileStoreTests`:增删改查、路径处理
  - [ ] `PromptBuilderTests`:心得摘要、上下文拼装
  - [ ] `HoldingsJSONTests`:JSON 解析边界
  - [ ] `AdvisoryResponseTests`:JSON 容错(字段缺失、类型错误)
- [ ] UI 微调:
  - [ ] 空状态文案 + 引导
  - [ ] Loading 状态
  - [ ] 错误提示文案
- [ ] 端到端联调(真机 + M3 实测):
  - [ ] 创建心得 → 输入持仓 → 提问 → 收到结构化建议
  - [ ] 截图导入跑通 3 个不同券商
- [ ] 性能检查:
  - [ ] 列表滚动流畅
  - [ ] 大文本 Markdown 渲染不卡
- [ ] 写 README.md(用户使用说明)

**验收标准**:
- ✅ 全部 AC 过
- ✅ 关键路径有单元测试覆盖
- ✅ 真机运行无明显 bug

---

## 5. 风险与依赖

### 5.1 风险清单

| ID | 风险 | 影响 | 概率 | 缓解措施 |
|---|---|---|---|---|
| R1 | MiniMax API 国内访问不稳定 | 操作建议/截图导入可能失败 | 中 | 重试机制 + 友好错误提示 |
| R2 | Vision 解析不同券商截图准确率差异 | 持仓导入需大量手动修正 | 中 | 强制预览修正流程;不阻断 |
| R3 | 心得太多时 Prompt token 浪费 | 成本上升 / 响应慢 | 低 | 30 天时间窗 + 摘要截断(详见 SPEC §5.3) |
| R4 | 大 Markdown 渲染卡顿 | 体验差 | 低 | 分段渲染 / 虚拟列表 |
| R5 | iOS Keychain 在模拟器行为差异 | 开发期困惑 | 低 | 真机测试为主 |
| R6 | UIActivityViewController 分享面板某些 App 不支持 | 备份可能分享失败 | 低 | 提供"保存到文件"作为兜底 |

### 5.2 依赖清单

| ID | 依赖 | 状态 | 备注 |
|---|---|---|---|
| D1 | MiniMax API Key | ⏳ 用户后续提供 | 必需,M3 调用前置 |
| D2 | 真机测试 | ⏳ 用户设备 | 模拟器对 Vision/Keychain 行为有差异 |
| D3 | 实盘持仓截图 | ⏳ 用户自备 | M3 + M4 联调用 |
| D4 | Xcode 15+ | ✅ 已有 | SwiftUI 4 需要 |

---

## 6. 测试策略

### 6.1 单元测试(必须)

| 模块 | 测试重点 |
|---|---|
| `FileStore` | 路径处理、特殊字符文件名、空目录、并发读写 |
| `PromptBuilder` | 心得摘要截断、持仓拼装、空数据降级 |
| `AdvisoryResponse` | Codable 容错(缺字段、类型错误) |
| `HoldingsDay` | Codable 边界(`source` 枚举、日期格式) |

### 6.2 集成测试(推荐)

| 场景 | 验证内容 |
|---|---|
| M3 Vision 解析 | 给一张测试截图 → 拿到 JSON → 校验字段 |
| M3 操作建议 | 给定模拟心得+持仓+问题 → 拿到 JSON → 校验结构 |
| 流式响应 | 验证流式分片能正确拼装 |
| 备份导出 | 跑完整导出流程,解压校验内容 |

### 6.3 UI 测试(可选,首版可省)

- 关键路径截图对比
- Tab 切换、Sheet 弹出等基础交互

---

## 7. 开发节奏建议

考虑到这是个人项目,业余时间开发,**建议节奏**:

- 每个 Milestone 完成后,在真机跑一遍,确认没问题再进下一个
- 不要跨 Milestone 同时改(避免冲突)
- 遇到 MiniMax API 行为异常,及时更新 SPEC 里的 Prompt 模板
- 重要的设计决策变更 → 同步更新 SPEC.md / PLAN.md(SDD 的纪律)

---

## 8. 当前待办(SPEC 评审通过后启动)

- [ ] 用户 review SPEC.md + PLAN.md
- [ ] 反馈调整意见
- [ ] 用户确认无问题后,启动 Milestone 1
- [ ] 提供 MiniMax API Key(任意 Milestone 开始前即可)

---

**文档结束。**
