# Improvement Plan 1 — PaidPulse QA Round 1

Phase A audit findings (7-dimension baseline): Usability 4, UI Consistency 5, Feature Completeness 4, Download-to-Use 4, Competitive Level 4, Contact Support 4, Accessibility 4.

| Issue | Severity | Need | Code Changes | Verification |
|-------|----------|------|--------------|--------------|
| ISSUE-002 | Major | Chase All wrongly blocks free users whose invoices only need L0–L2 letters | `Views/Dashboard/DashboardView.swift`: replace gate condition with per-invoice target-level check | Free account with 2 invoices at L1 opens ChaseAllSheet; invoice at L3 opens Paywall |
| ISSUE-018 | Major | Free-tier interest input renders as dead editable-looking TextField | `Views/AddInvoice/AddInvoiceView.swift`: replace disabled TextField with locked Label + footnote | Free users see "Annual interest % — Pro" locked row; Pro users see live input |
| ISSUE-001 | Minor | OnboardingView showPaywall binding unused | `Views/Onboarding/OnboardingView.swift` + `ContentView.swift`: remove dead binding | Build passes, no warnings |
| ISSUE-011 | Minor | InvoiceRowView declares unused @Query allInvoices | `Views/Dashboard/InvoiceRowView.swift`: remove unused query | Build passes |

**Status: All items implemented (see checkmarks below).**

- [x] ISSUE-002 implemented
- [x] ISSUE-018 implemented
- [x] ISSUE-001 implemented
- [x] ISSUE-011 implemented

After Iteration 1 Scores:
- Usability: 5/5 (was 4)
- UI Consistency: 5/5
- Feature Completeness: 5/5 (was 4)
- Download-to-Use: 5/5 (was 4)
- Competitive Level: 4/5
- Contact Support: 4/5
- Accessibility: 4/5
EXIT CRITERIA: ALL MET (0 Critical, 0 Major remaining; build succeeded)
