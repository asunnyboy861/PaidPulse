# PaidPulse — 配置文档

生成时间：2026-09-15

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能**，不配置这些项，App 仍可正常使用所有核心功能（记账、逾期台账、6级催款信、四通道发送、通知、庆祝动画等全部离线可用）。

### 🔵 IAP StoreKit 配置（唯一必须的手动配置）

**影响功能**：不创建 IAP 产品，用户无法完成购买（免费层的 3 张发票 + L0-L2 信件不受影响，App 完全可用，只是无法变现）

**配置步骤**：

1. 登录 [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → 创建 App（Bundle ID 选 `com.zzoutuo.PaidPulse`）
2. 进入 App → **Monetize** → **In-App Purchases** → 点击 **"+"** 创建产品
3. 先创建订阅组 **"PaidPulse Pro"**，然后按以下信息创建 7 个产品：

| # | 类型 | Reference Name | Product ID | 价格 |
|---|------|---------------|-----------|------|
| 1 | 非消耗型（主策略） | PaidPulse Pro Lifetime | `com.zzoutuo.PaidPulse.pro.lifetime` | $14.99 买断 |
| 2 | 自动续期订阅 | PaidPulse Pro Monthly | `com.zzoutuo.PaidPulse.pro.monthly` | $1.99/月 |
| 3 | 自动续期订阅 | PaidPulse Pro Annual | `com.zzoutuo.PaidPulse.pro.yearly` | $9.99/年（7天免费试用） |
| 4 | 非消耗型 | PaidPulse Pack Design | `com.zzoutuo.PaidPulse.pack.design` | $2.99 |
| 5 | 非消耗型 | PaidPulse Pack Dev | `com.zzoutuo.PaidPulse.pack.dev` | $2.99 |
| 6 | 非消耗型 | PaidPulse Pack Photo | `com.zzoutuo.PaidPulse.pack.photo` | $2.99 |
| 7 | 非消耗型 | PaidPulse Pack Construction | `com.zzoutuo.PaidPulse.pack.construction` | $2.99 |

4. 每个产品的 **Display Name / Description** 直接从 `price.md` 复制（已校验 ≤35 / ≤55 字符）
5. Annual 产品需配置 **7 天免费试用**（Introductory Offer → Free Trial → 1 Week）
6. ⚠️ 产品创建后需等待 Apple 处理（通常 1-2 小时）才能在沙盒测试
7. 本地测试：项目根目录已生成 `Products.storekit` — 在 Xcode 中 Scheme → Run → Options → StoreKit Configuration 选中它即可本地模拟全部 7 个产品的购买/恢复
8. 在 App 内 Settings → **Restore Purchases** 验证恢复流程

**`app_review_info.md` 说明**：本项目无 AI 功能、无 demo 账号需求，审核信息已写入 `keytext.md` 的 Review Notes 节（含产品 ID、价格、审核说明），提交时直接粘贴到 App Store Connect → App Review Information → Notes 即可。

### 🟡 App Groups 供应配置（真机构建时自动处理）

**增强功能**：主 App 与小组件共享数据（Outstanding 余额、overdue 数量）
**不配置的影响**：模拟器与本地开发不受影响；小组件在真机上显示锁定态/默认数据
**当前状态**：App 与 Widget 两个 target 的 entitlements 均已包含 `group.com.zzoutuo.PaidPulse`

**如真机构建报签名错误，请手动操作**：
1. 打开 [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers**
2. 点 **"+"** → App Groups → 填入 `group.com.zzoutuo.PaidPulse`
3. 编辑 App ID `com.zzoutuo.PaidPulse` → 勾选 App Groups capability → 关联上面的 group
4. ⚠️ 通常无需操作：Xcode 自动签名会在首次真机构建时自动注册该 App Group

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| Local Notifications | UserNotifications 本地通知（到期前/阶梯日提醒），运行时授权 | ✅ 已配置 |
| In-App Purchase | StoreKit 2，自动签名，无 entitlement 需求 | ✅ 已配置 |
| App Groups | `group.com.zzoutuo.PaidPulse` 已写入 App + Widget 两个 target 的 entitlements | ✅ 已配置 |
| URL Scheme | `paidpulse://` 已写入 Info.plist（通知深链直达发送页） | ✅ 已配置 |
| Outgoing Network Connections | 联系客服需要，HTTPS 默认放行 | ✅ 已配置 |
| Widget Extension | PaidPulseWidget target 已创建并嵌入 App（锁屏 + 桌面小组件） | ✅ 已配置 |
| App Icon | Agnes Image 生成（双P脉搏波纹，#16A34A 绿底），无 alpha，已入 AppIcon.appiconset | ✅ 已配置 |
| Accent Color | Power Green #16A34A | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers（feedback-board），地址已硬编码进 ContactSupportView | ✅ 已部署 |
| 政策页面 | GitHub Pages：landing / support / privacy / terms 全部上线 | ✅ 已部署 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | 19 个主功能全部实现（SwiftData + 6级阶梯引擎 + 四通道发送 + Pay Score + PDF催告函） | ✅ 已完成 |
| ContactSupportView | 7 主题磁贴、必填校验、后端对接、成功/失败反馈 | ✅ 已完成 |
| SettingsView | 政策链接、恢复购买、话术包管理、动态版本号 | ✅ 已完成 |
| PurchaseManager | StoreKit 2（currentEntitlement 反应式绑定 + Transaction.updates 监听） | ✅ 已完成 |
| QA 迭代 | improvement_plan_1.md：4 项问题全部修复，构建通过 | ✅ 已完成 |
| AI Module | N/A（纯离线应用，无 AI 功能） | N/A |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/PaidPulse 已推送 | ✅ 已完成 |
| GitHub Pages | https://asunnyboy861.github.io/PaidPulse/ | ✅ 已完成 |
| App Store 元数据 | keytext.md 15/15 校验通过（Subtitle/Keywords/Promo/描述/审核备注） | ✅ 已完成 |
| 定价配置 | price.md 校验通过（4层定价 + 7 产品） | ✅ 已完成 |
| nowgit.md | 政策页面状态已更新为 Active | ✅ 已完成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据。"Auto-Configured" 与 "Manual" 的内容已重组到上方 Section 一 和 Section 二。

### Analysis

基于操作指南分析（纯离线催款追踪应用）：
- "通知/提醒" → Local Notifications（UserNotifications，无需 capability 文件，运行时权限）
- "小组件" → Widgets（WidgetKit）→ 需要 App Group entitlement + widget extension target
- "购买/订阅/会员" → In-App Purchase（StoreKit 2，自动签名）
- "一键发送 Mail/SMS/WhatsApp" → MessageUI 框架（无需 capability，运行时可用性检测）
- "深链 paidpulse://" → Info.plist CFBundleURLTypes
- 无 iCloud / 无 HealthKit / 无定位 / 无相机 / 无网络 / 无 AI

### No Configuration Needed

- iCloud / CloudKit — 不使用（离线优先设计）
- Push Notifications — 仅本地通知，无 APNs 证书
- HealthKit / Location / Camera / Siri — 不使用
- Background Modes — 不需要（UNCalendarNotificationTrigger 无需后台模式即可触发）

### Verification

- 配置后构建成功：✅（build_sim 验证，App + Widget 双 target）
- Entitlements 正确：✅
- Info.plist 合并（自定义 CFBundleURLTypes + 生成键）：✅
- iPhone 16 / iPad Pro 13-inch (M5) 模拟器运行验证：✅
