# PaidPulse — Overdue Invoice Chaser · iOS Development Guide

> Translated & adapted from Chinese guide TR-20260913 (Freelancer催款追踪与升级信). Pain-point grade: 💎 Diamond (90/100).

## Executive Summary

**Product Vision**: PaidPulse is a fully-offline, zero-account, zero-third-party-SDK iOS app that helps US freelancers (70M market) chase overdue invoices with dignity. It turns the most painful part of freelancing ("chasing money is the worst part") into a dopamine loop: the app writes the perfect follow-up letter at each escalation level, the user sends it in one tap, and marking an invoice paid triggers confetti + a "Cha-ching" sound + a running Recovered total.

**Target Audience**: US freelance designers, developers, writers, consultants, photographers (r/freelance, r/Freelancers demographics).

**Key Differentiators** (vs. all competitors):
1. **True 6-level escalation ladder engine** (state machine, not copy-paste templates) — one-tap send via Mail / SMS / WhatsApp deep link / Copy
2. **Late interest calculator** (daily simple interest + optional late fee) — gives users legal leverage
3. **Client Pay Score** (A–F grade, average delay days, on-time rate) — exclusive social-currency feature
4. **Formal Demand Letter PDF** (PDFKit, court-ready documentation) — no competitor has this
5. **Fully offline + Data Not Collected privacy label** — competitors all upload client lists to the cloud
6. **Lifetime purchase $14.99** (no subscription trap) + free tier of 3 active invoices

**Monetization**: Freemium. Free = 3 active invoices + L1/L2 templates. Pro = $14.99 lifetime (primary), $1.99/mo or $9.99/yr subscription (bypass), $2.99 industry phrase packs (optional IAP).

## Competitive Analysis

| App | Price | Strengths | Weaknesses | Our Advantage |
|-----|-------|-----------|------------|---------------|
| FreshBooks (Web SaaS) | $23/mo ($276/yr) | Full accounting, 3 reminder rules, Pay Now buttons | Expensive; chasing is an add-on; cloud-only | 1/18th the annual cost, offline, native iOS |
| PaidYet (iOS, HEIMS LLC) | Free 3 / $0.99/mo Pro | Overdue buckets (1-7/8-14/15+), copyable polite templates | Subscription; copy-paste only (no direct send); no escalation state machine; no interest calc; no Pay Score; no PDF; no widgets | True engine + direct send + interest + Pay Score + PDF + lifetime price |
| Invoice Maker Tofu (iOS) | $9.99/week (!) | Invoice creation | Absurd pricing ($520/yr); invoicing-first, chasing shallow | $14.99 once, chasing-first |
| Chaser (Web SaaS) | $40+/mo | Enterprise AR automation | For 50+ invoices/month companies; overkill for freelancers | Personal-scale, one-tap, no account |
| Nudge (Web SaaS) | $9.99/mo | SMS + email auto-reminders | Requires uploading client data to cloud | Zero data collection, works offline |

## Apple Design Guidelines Compliance

- **iOS 26 Liquid Glass native style**: all-SwiftUI system components (NavigationStack, List, Toolbar, sheets). Zero custom wheels → system-grade polish.
- **HIG Navigation**: TabView-free single-window design — Dashboard root → detail pushes → modal sheets for compose/send.
- **Color semantics**: green = paid/recovered, red = overdue urgency, orange = approaching due. Primary color **Power Green #16A34A**. Dark-mode first.
- **Typography**: SF Pro; money amounts use `.system(size: 34, weight: .bold, design: .rounded)`.
- **Dynamic Type**: all text uses semantic fonts; nothing clipped at accessibility sizes.
- **Notifications**: user-triggered scheduling only, clear permission copy ("We'll remind you exactly when to follow up").
- **Localization**: US English primary; all user-visible strings in String Catalog; US date format `Sep 30, 2026`, currency `$1,500.00` USD prefix.
- **App Store privacy label**: **Data Not Collected** — no analytics, no crash SDK, no network calls except system mail/SMS/WhatsApp handoff.

## Technical Architecture

- **Language**: Swift 5.9+, Swift Concurrency
- **UI**: SwiftUI (iOS 17+), SwiftData for persistence
- **Data**: SwiftData (Client / Invoice / ReminderEvent / AppSettings), UserDefaults for onboarding flags
- **Notifications**: UserNotifications framework (UNCalendarNotificationTrigger)
- **Send channels**: MessageUI (MFMailComposeViewController, MFMessageComposeViewController), wa.me URL scheme, UIPasteboard, mailto: fallback
- **PDF**: UIKit UIGraphicsPDFRenderer + PDFKit for preview/share
- **IAP**: StoreKit 2 (non-consumable lifetime + auto-renewable subscription + non-consumable packs)
- **Widgets**: WidgetKit (lock screen accessory + home screen medium)
- **Haptics/Sound**: CoreHaptics custom "cha-ching" vibration + system sound; confetti via Canvas/TimelineView animation
- **Zero third-party dependencies**: no SPM pods, no SDKs

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | 30-second Add Invoice | Dashboard → + button → form (Client autocomplete / Amount / Due Date required; rest optional) → Done | Client name (existing autocomplete or new), amount, due date, optional: email, phone, terms days, interest rate, late fee %, note | Validate 3 required fields; generate INV-#### number; create/find Client; insert Invoice | New invoice row in ledger; success haptic | SwiftData Invoice + Client | Invoice appears in Dashboard within 1s; number auto-increments |
| 2 | Overdue Ledger with buckets | Open Dashboard → scroll grouped list | none (derived) | Compute `daysOverdue` live from dueDate via Calendar; group into buckets: Upcoming / Due today / 1-7 / 8-14 / 15-30 / 30+ days | Grouped list with red/orange badges per bucket | none (derived state) | Buckets match day-diff math; DST-safe |
| 3 | 6-level Escalation Ladder Engine | Automatic on app open / data change | daysOverdue | Pure-function state machine: stage(forDaysOverdue) ∈ {L0 due today, L1 +3 Polite Nudge, L2 +7 Friendly Follow-up, L3 +14 Firm Reminder, L4 +30 Formal Demand, L5 +45 Final Notice}; advance-only rule `stage = max(current, computed)` | Invoice.currentStage; stage-change triggers letter preview + next notification | Invoice.currentStage Int 0-5 | Stage never regresses; manual skip-ahead allowed |
| 4 | Letter Template Engine | Invoice detail → letter preview card | Invoice + AppSettings + level | Variable substitution ({client},{number},{amount},{days},{dueDate},{interest},{total},{senderName},{paymentInstructions}) from 6 templates (invoiceninja-grade tone + Reddit-verified one-liner style) | Editable subject + body text | Templates bundled in JSON/Swift | All 6 levels render correct tone (Friendly→Final); user can edit before send |
| 5 | One-tap Send (4 channels) | Send page → tap channel button | Client email/phone, rendered letter | Mail: MFMailComposeViewController (mailto: fallback); SMS: MFMessageComposeViewController; WhatsApp: wa.me/<digits>?text= URL-encoded; Copy: UIPasteboard | System composer opens; on send/completion write ReminderEvent | SwiftData ReminderEvent (level, channel, sentAt, letterSnapshot) | Every send persists snapshot (evidence chain); works offline |
| 6 | Late Interest Calculator | Automatic on detail/letter | annualInterestRate %, lateFeePercent, outstanding | `interest = outstanding × rate/365 × days` in Decimal, rounded 2dp; show formula breakdown (principal × rate × days) | Accrued interest displayed on L3+ letters and detail card | Invoice.annualInterestRate, lateFeePercent (Decimal) | Matches manual math; transparent formula shown |
| 7 | Notification Scheduling | Auto after invoice create/edit/send/mark-paid | invoice state | Rebuild schedule: remove ALL pending for invoice (id+level ids), then register future ladder days within rolling 14-day window (≤64 pending cap) | Local notifications "Chase invoice #X?" with invoiceId payload | UNUserNotificationCenter | Tapping notification deep-links `paidpulse://invoice/<id>` to send page; Mark Paid cancels all |
| 8 | Mark Paid Satisfaction Loop | Invoice detail or swipe-left → Mark Paid | paidAmount (default full) | Idempotent transaction: set status=paid + paidDate → cancel pending notifications → update client stats → add to Recovered total → trigger confetti + cha-ching haptic/sound | Full-screen green gradient + confetti + "$X recovered" pop + Recovered counter animation | Invoice.paidDate/paidAmount; AppSettings.recoveredTotal | Celebration plays once; counter increments correctly; re-tap safe |
| 9 | Dashboard | Launch → Dashboard | derived | Sum Outstanding, count Overdue, sum Recovered; big rounded bold numbers | 3 stat cards + bucketed list + "Chase All" button | derived | Numbers accurate; pull-to-refresh animates counter |
| 10 | Chase All (batch) | Dashboard → Chase All button | all unpaid invoices at/past stage | Generate letter for each actionable invoice; present sequential send queue | Batch send list, each one-tap sendable | ReminderEvents as sent | Free-tier gate: paywall on first use if applicable; "All chased" green state after |
| 11 | Client Pay Score | Client profile (tap client name) | client's paid invoices | avgDelayDays (mean of delayDaysAtPayment), onTimeRate %, payScore 0-100 → A-F grade ring | Grade ring (A green → F red), avg delay days, invoice timeline; F-grade warning banner + "suggest 50% deposit" one-tap script | derived (never stored — computed live) | New client shows neutral 70; F client shows red banner |
| 12 | Formal Demand Letter PDF | Invoice detail (L4/L5) → Export PDF | rendered finalNotice letter + settings | UIGraphicsPDFRenderer US Letter (612×792): header, date, from/to, RE line, body, interest breakdown, pagination | Share sheet (print/save/share) | Generated on demand (no storage) | PDF renders multi-page correctly; share sheet works |
| 13 | Widgets (lock screen + home) | iOS widget gallery → add | outstanding total + overdue count from shared SwiftData/app group | TimelineProvider recomputes daily + on data change | Lock screen accessory: "3 overdue · $4,200"; home medium: mini bucket list | App Group shared container | Updates on invoice changes; no stale data |
| 14 | 60-second Onboarding | First launch only | 4 screens: (1) tagline "Get paid without the awkward." + Add First Invoice button → (2) 3-field form → (3) notification permission → (4) Dashboard | OnboardingComplete UserDefaults flag | Dashboard ready | UserDefaults | Total <60s; skippable except form; never shown again |
| 15 | Paywall / Entitlement Gate | Triggered at: adding 4th invoice, first Chase All, first L3+ template | none | EntitlementGate single point: `isPro = lifetime || subscription || (trial)`; free limit 3 active invoices | StoreKit 2 paywall sheet: lifetime $14.99 primary, $1.99/mo & $9.99/yr secondary, restore purchases, legal links | StoreKit 2 transactions | Free users blocked at limit with paywall; purchase unlocks instantly; restore works |
| 16 | Industry Phrase Packs (IAP) | Paywall → phrase packs | pack selection | Non-consumable $2.99 each (Design Studio / Dev & Agency / Photography / Construction); adds 30+ tone-varied templates per pack | Extra templates selectable on send page | StoreKit 2 + owned-pack flags | Purchase adds templates immediately; non-owned packs show lock |
| 17 | Settings | Settings tab/button → form | businessName, paymentInstructions, defaultInterestRate, lateFeeEnabled, invoice number reset | Validate & save to AppSettings | Letters use updated values; next invoice number sequence | SwiftData AppSettings (singleton) | Changes reflected in next rendered letter |
| 18 | Rating Prompt | After 3rd successful Mark Paid | recoveredCount | Request review via SKStoreReviewController (once at peak moment) | System rating dialog | UserDefaults counter | Shows exactly once at 3rd mark-paid; never pesters |
| 19 | Share Recovery Card | Post-celebration → Share | Recovered total | Render shareable card "PaidPulse helped me recover $12,400" | ShareLink to Instagram/X/system | none | Share sheet opens with pre-rendered card image |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail | Interaction |
|---|--------|-------------|--------|-------------|
| 1.1 | Add Invoice | Client autocomplete | Type-ahead over existing Client names; "Add new" creates client inline | Typing in client field |
| 1.2 | Add Invoice | Terms presets | Net15/Net30/Net45 chips set dueDate = issueDate + terms | Tap chip |
| 2.1 | Ledger | Swipe left = Mark Paid | Quick-action on row | Swipe gesture |
| 2.2 | Ledger | Context menu | Long-press row → quick send menu (levels), Mark Paid, Edit, Delete | Long press |
| 4.1 | Letter | Tone labels | Friendly→Final color-coded tone chip on send page | Display |
| 4.2 | Letter | Edit before send | Letter body is editable TextEditor; edits captured in snapshot | Edit text |
| 5.1 | Send | Channel availability | Hide WhatsApp button if phone empty; hide Mail if email empty & canSendMail false | Adaptive UI |
| 7.1 | Notifications | Deep link | `paidpulse://invoice/<id>` routes to that invoice's send page | Notification tap |
| 8.1 | Mark Paid | Partial payment | Mark Partial enters paidAmount < total; outstanding recalculates; invoice stays active | Optional flow |
| 9.1 | Dashboard | Recovered counter animation | Number rolls up on pull-to-refresh / after mark-paid | Animation |
| 15.1 | Paywall | Trial | Subscription $9.99/yr includes 7-day free trial | StoreKit |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Add Invoice → Ledger | F1 | F2 | New Invoice object | On save |
| Ledger → Engine | F2 | F3 | daysOverdue (computed live) | Every render/data change |
| Engine → Templates | F3 | F4 | currentStage / level | Stage advance |
| Templates → Send | F4 | F5 | Rendered subject/body | Send page open |
| Send → ReminderEvent | F5 | persistence | letterSnapshot + channel + level | Send completion |
| Send → Notifications | F5 | F7 | invoice state | After send (rebuild) |
| Mark Paid → Notifications | F8 | F7 | invoice.id | Cancel all pending |
| Mark Paid → Pay Score | F8 | F11 | paidDate/dueDate | Stats recompute (derived) |
| Mark Paid → Dashboard | F8 | F9 | amount | Recovered total + |
| Mark Paid → Rating | F8 | F18 | count == 3 | 3rd mark-paid |
| Paywall ↔ Gate | F15 | F1/F10/F4 | isPro flag | 4th invoice / Chase All / L3+ |
| Settings → Letters | F17 | F4 | senderName, paymentInstructions | Every render |
| Settings → Interest | F17 | F6 | defaultInterestRate | New invoice default |
| Widgets ← Ledger | F13 | F2 | App Group query | Timeline refresh |

**VERIFICATION**: 19 primary features vs. Chinese guide sections 5.1 (items 1-7), 5.2 (8-10), 7.3 (onboarding), 10.3 (monetization), 11.2 (UI specs incl. share card), 9.x (settings implied) — ✅ MATCH.

## ⚠️ Data Flow Diagram (MANDATORY)

```
Feature: Overdue Engine (core)
┌───────────────────────────────────────────────────────────┐
│  Input: Invoice.dueDate (single source of truth)          │
│    │                                                       │
│  EscalationEngine (pure function, no storage)             │
│    └── daysOverdue = Calendar.dateComponents(.day,        │
│         from: startOfDay(due), to: startOfDay(now))       │
│    └── stage = max(currentStage, computed)  // never regress│
│    │                                                       │
│  Persistence: Invoice.currentStage (Int 0-5) only         │
│    │                                                       │
│  Display: bucket badge + stage progress bar (6 segments)  │
│    │                                                       │
│  Side effects: letter preview refresh +                   │
│    NotificationScheduler.rebuild(invoice)                 │
└───────────────────────────────────────────────────────────┘

Feature: Send (evidence chain)
  Letter rendered → user edits → channel dispatch
  → ReminderEvent(invoiceId, level, channel, sentAt, letterSnapshot) inserted
  → rebuild notifications → UI shows "chased" checkmark + next date

Feature: Mark Paid (idempotent, atomic)
  status=paid, paidDate, paidAmount → cancel ALL pending notifs (id+level)
  → derived client stats update → recoveredTotal += amount
  → confetti + CoreHaptics cha-ching → Dashboard counters animate

Feature: Interest (transparent)
  outstanding × (annualRate/100) / 365 × daysOverdue — all Decimal,
  displayed as formula breakdown, never recomputed/stored redundantly
```

## Module Structure

```
PaidPulse/
├── PaidPulseApp.swift            // @main, SwiftData container, deep-link routing
├── Models/
│   ├── Client.swift              // @Model
│   ├── Invoice.swift             // @Model (Decimal amounts, computed daysOverdue)
│   ├── ReminderEvent.swift       // @Model evidence snapshot
│   ├── AppSettings.swift         // @Model singleton
│   └── EscalationLevel.swift     // enum + EscalationEngine pure functions
├── Services/
│   ├── TemplateLibrary.swift     // 6-level templates + variable renderer
│   ├── SendService.swift         // Mail/SMS/WhatsApp/Copy + ReminderEvent write
│   ├── NotificationScheduler.swift // clear-then-build, 14-day rolling window
│   ├── DemandLetterPDF.swift     // UIGraphicsPDFRenderer
│   ├── PurchaseManager.swift     // StoreKit 2
│   ├── EntitlementGate.swift     // single free-tier checkpoint
│   └── Currency.swift            // Decimal formatting
├── Views/
│   ├── Dashboard/ (DashboardView, InvoiceRowView, ChaseAllSheet)
│   ├── Invoice/ (InvoiceDetailView, SendPageView, StageProgressBar)
│   ├── AddInvoice/ (AddInvoiceView)
│   ├── Client/ (ClientProfileView, PayScoreRing)
│   ├── Onboarding/ (OnboardingView)
│   ├── Paywall/ (PaywallView)
│   └── Settings/ (SettingsView)
├── Widgets/ (PaidPulseWidget extension: LockscreenWidget, HomeWidget)
└── Resources/ (Localizable.xcstrings, templates.json, Assets)
```

## Implementation Flow

1. SwiftData models (Client, Invoice, ReminderEvent, AppSettings) with Decimal + computed properties
2. EscalationEngine pure functions + unit-testable day math (Calendar-based, DST-safe)
3. Dashboard UI: 3 stat cards + bucketed list + add flow
4. TemplateLibrary (6 levels, JSON-bundled, variable rendering)
5. NotificationScheduler (clear-then-build, 14-day window, deep link payload)
6. SendService 4 channels + ReminderEvent persistence
7. Mark Paid transaction + confetti/haptics + Recovered counter
8. StoreKit 2 PurchaseManager + EntitlementGate + PaywallView
9. Client Pay Score profile + F-grade deposit script
10. DemandLetterPDF + share sheet
11. Widgets (app group + WidgetKit)
12. Onboarding + rating prompt + share card
13. Polish: dark mode, Dynamic Type, accessibility labels

## UI/UX Design Specifications

- **Colors**: Power Green #16A34A (primary/paid), red #DC2626 (overdue), orange #F59E0B (due soon), semantic backgrounds for dark-mode-first
- **Numbers**: `.system(size: 34, weight: .bold, design: .rounded)` for money; bucket badges capsule-style
- **Layout**: Dashboard one screen: 3 stat cards top, bucket sections, Chase All prominent bottom
- **Animations**: stage progress segments light up sequentially; Recovered counter roll-up; confetti particle burst + green gradient flash on mark-paid; send success checkmark + haptic
- **Gestures**: swipe-left Mark Paid; long-press context menu (quick send levels)
- **US conventions**: `Sep 30, 2026` dates, `$1,500.00` USD, no registration walls, no ads

## Code Generation Rules

1. Money is **Decimal only** (never Double); format via Decimal.FormatStyle.Currency
2. daysOverdue **always computed live** from dueDate via `Calendar.dateComponents` — never stored, never TimeInterval/86400
3. State machine **advance-only**: `stage = max(current, computed)`; manual skip allowed, auto-regress forbidden
4. Every send **must persist a ReminderEvent snapshot** (text + channel + timestamp)
5. Notifications: **clear-then-build**, rolling 14-day window, respect 64-pending cap
6. Mark Paid is an **idempotent atomic** operation (status → notifications → stats → recovered)
7. **Zero third-party SDKs**, zero network calls from app code
8. All user-facing strings in **String Catalog**
9. Paywall gating **only** through EntitlementGate single point
10. Version read dynamically via `Bundle.main.infoDictionary` — never hardcode

## Build & Deployment Checklist

- [x] Xcode project exists (user-created): PaidPulse.xcodeproj
- [ ] Bundle ID com.zzoutuo.PaidPulse, iOS 17.0 minimum
- [ ] App Group for widgets: group.com.zzoutuo.PaidPulse
- [ ] IAP products configured in App Store Connect: `com.zzoutuo.PaidPulse.lifetime` ($14.99 non-consumable), `com.zzoutuo.PaidPulse.monthly` ($1.99/mo), `com.zzoutuo.PaidPulse.yearly` ($9.99/yr + 7-day trial), 4 phrase packs ($2.99 each)
- [ ] StoreKit configuration file for local testing
- [ ] Build & run on iPhone + iPad simulators
- [ ] Privacy label: Data Not Collected
- [ ] URL scheme registered: paidpulse://
