# Git Repositories — PaidPulse

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | PaidPulse |
| **Git URL** | git@github.com:asunnyboy861/PaidPulse.git |
| **Repo URL** | https://github.com/asunnyboy861/PaidPulse |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/PaidPulse/ | ⏳ Pending |
| Support | https://asunnyboy861.github.io/PaidPulse/support.html | ⏳ Pending |
| Privacy Policy | https://asunnyboy861.github.io/PaidPulse/privacy.html | ⏳ Pending |
| Terms of Use | https://asunnyboy861.github.io/PaidPulse/terms.html | ⏳ Pending |

## Repository Structure

```
PaidPulse/
├── PaidPulse.xcodeproj/           # Xcode Project (App + Widget targets)
├── PaidPulse/                     # iOS App Source Code
│   ├── Models/                    # Client, Invoice, ReminderEvent, AppSettings, EscalationLevel
│   ├── Services/                  # TemplateLibrary, PackLibrary, SendService, NotificationScheduler,
│   │                              # DemandLetterPDF, PurchaseManager, EntitlementGate, WidgetBridge
│   ├── Views/                     # Dashboard, Invoice, AddInvoice, Client, Onboarding, Paywall, Settings
│   ├── PaidPulseWidget/           # (separate top-level target folder)
│   └── Assets.xcassets
├── PaidPulseWidget/               # WidgetKit Extension (lock screen + home screen)
├── docs/                          # Policy Pages (GitHub Pages source — added in PHASE 7)
├── .github/workflows/
│   └── deploy.yml
├── us.md
├── capabilities.md
├── icon.md
├── price.md
├── nowgit.md
├── keytext.md              # ⚠️ EXCLUDED from repo (.gitignore — confidential ASO strategy)
├── COMPETITOR_REPORT.md    # ⚠️ EXCLUDED from repo (.gitignore — confidential competitor analysis)
```

## Build Targets

| Target | Bundle ID | Purpose |
|--------|-----------|---------|
| PaidPulse | com.zzoutuo.PaidPulse | Main app (iOS 17.0+) |
| PaidPulseWidget | com.zzoutuo.PaidPulse.Widget | WidgetKit extension (App Group shared) |
