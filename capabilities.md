# Capabilities Configuration — PaidPulse

## Analysis
Based on operation guide analysis (pure-offline invoice chasing app):
- "通知/提醒" → Local Notifications (UserNotifications — no capability file needed, runtime permission only)
- "小组件" → Widgets (WidgetKit) → requires App Group entitlement + widget extension target
- "购买/订阅/会员" → In-App Purchase (StoreKit 2 — no entitlement file needed, automatic signing)
- "一键发送 Mail/SMS/WhatsApp" → MessageUI framework (no capability, runtime availability check)
- "深链 paidpulse://" → CFBundleURLTypes in Info.plist
- No iCloud / no HealthKit / no location / no camera / no network / no AI

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| In-App Purchase (StoreKit 2) | ✅ Configured | Automatic signing — no entitlement required; products configured at App Store Connect phase |
| Local Notifications | ✅ Configured | UserNotifications framework — runtime permission prompt in onboarding |
| URL Scheme `paidpulse://` | ✅ Configured | `PaidPulse/Info.plist` → CFBundleURLTypes (merged with generated plist) |
| App Groups (`group.com.zzoutuo.PaidPulse`) | ✅ Configured | `PaidPulse/PaidPulse.entitlements` + CODE_SIGN_ENTITLEMENTS in Debug/Release |
| Bundle ID fix | ✅ Done | `com.zzoutuo.PaidPulse.PaidPulse` → `com.zzoutuo.PaidPulse` in all app configs |
| Accent Color | ✅ Done | Power Green #16A34A in AccentColor.colorset |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| App Group provisioning | ⏳ Verify on device build | Automatic signing registers `group.com.zzoutuo.PaidPulse` on first real-device build. Simulator builds work immediately. |
| IAP products | ⏳ App Store Connect | Create 7 products after app record exists (documented in price.md) |

## No Configuration Needed
- iCloud / CloudKit — not used (offline-first by design)
- Push Notifications — local notifications only, no APNs certificate
- HealthKit / Location / Camera / Siri — not used
- Background Modes — not needed (UNCalendarNotificationTrigger fires without background modes)

## Verification
- Build succeeded after configuration: ✅ (verified via build_sim)
- All entitlements correct: ✅
- Info.plist merge (custom CFBundleURLTypes + generated keys): ✅
