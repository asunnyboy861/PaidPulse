# Pricing Configuration — PaidPulse

## Monetization Model: Freemium with IAP

Free download with a 3-active-invoice free tier. Pro is unlocked by a lifetime non-consumable (primary) OR an auto-renewable subscription (bypass). Optional industry phrase packs are separate non-consumable content add-ons. Fully offline — zero marginal cost supports lifetime pricing.

## Subscription Group
- **Group Name**: PaidPulse Pro
- **Reference Name**: PaidPulse Pro
- **Products in group**: PaidPulse Pro Monthly, PaidPulse Pro Annual

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: PaidPulse Pro Monthly
- **Product ID**: `com.zzoutuo.PaidPulse.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $1.99 USD per month
- **Display Name**: `PaidPulse Pro Monthly` (20 chars, ≤35 ✅)
- **Description**: `Unlimited invoices and all Pro tools` (36 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: PaidPulse Pro
- **Restore Purchases**: ✅ Required
- **Note**: Lowest entry price; cancel anytime. Same feature set as Lifetime — choose this for flexibility, choose Lifetime for one-time ownership.

### 2. Yearly Subscription
- **Reference Name**: PaidPulse Pro Annual
- **Product ID**: `com.zzoutuo.PaidPulse.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $9.99 USD per year (58% savings vs monthly)
- **Display Name**: `PaidPulse Pro Annual` (20 chars, ≤35 ✅)
- **Description**: `All Pro tools, one year, 7-day trial` (36 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: PaidPulse Pro (same group as monthly)
- **Restore Purchases**: ✅ Required
- **Note**: Same feature set as Lifetime — choose this for the 7-day free trial and lowest yearly cost; choose Lifetime to never renew.

## One-Time Purchases (Non-Consumable)

### 1. Pro Lifetime (PRIMARY tier)
- **Reference Name**: PaidPulse Pro Lifetime
- **Product ID**: `com.zzoutuo.PaidPulse.pro.lifetime`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $14.99 USD (one-time)
- **Display Name**: `PaidPulse Pro Lifetime` (22 chars, ≤35 ✅)
- **Description**: `Pay once. All Pro features forever` (34 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Note**: Same feature set as the subscription — differentiated by permanent ownership: pay once, no renewals ever. Best value for anyone past ~8 months of use.

### 2. Design Studio Phrase Pack
- **Reference Name**: PaidPulse Pack Design
- **Product ID**: `com.zzoutuo.PaidPulse.pack.design`
- **Type**: Non-consumable (one-time purchase, permanent content)
- **Price**: $2.99 USD (one-time)
- **Display Name**: `Design Studio Pack` (18 chars, ≤35 ✅)
- **Description**: `30+ reminder letters for design clients` (39 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Boundary note**: Adds industry tone-varied letter templates ONLY. Does NOT unlock Pro features (invoice limits, L3+ base templates are Pro/Lifetime territory).

### 3. Dev & Agency Phrase Pack
- **Reference Name**: PaidPulse Pack Dev
- **Product ID**: `com.zzoutuo.PaidPulse.pack.dev`
- **Type**: Non-consumable (one-time purchase, permanent content)
- **Price**: $2.99 USD (one-time)
- **Display Name**: `Dev & Agency Pack` (17 chars, ≤35 ✅)
- **Description**: `30+ reminder letters for dev work` (33 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Boundary note**: Adds industry tone-varied letter templates ONLY. Does NOT unlock Pro features.

### 4. Photography Phrase Pack
- **Reference Name**: PaidPulse Pack Photo
- **Product ID**: `com.zzoutuo.PaidPulse.pack.photo`
- **Type**: Non-consumable (one-time purchase, permanent content)
- **Price**: $2.99 USD (one-time)
- **Display Name**: `Photography Pack` (16 chars, ≤35 ✅)
- **Description**: `30+ reminder letters for photo clients` (38 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Boundary note**: Adds industry tone-varied letter templates ONLY. Does NOT unlock Pro features.

### 5. Construction Phrase Pack
- **Reference Name**: PaidPulse Pack Construction
- **Product ID**: `com.zzoutuo.PaidPulse.pack.construction`
- **Type**: Non-consumable (one-time purchase, permanent content)
- **Price**: $2.99 USD (one-time)
- **Display Name**: `Construction Pack` (17 chars, ≤35 ✅)
- **Description**: `30+ reminder letters for contracting` (36 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Boundary note**: Adds industry tone-varied letter templates ONLY. Does NOT unlock Pro features.

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - 3 active invoices at a time
  - L0–L2 escalation letters (Due Today, Polite Nudge, Friendly Follow-up)
  - Local notification reminders
  - All 4 send channels (Email / Text / WhatsApp / Copy)
  - Mark Paid celebration + Recovered counter
  - Client Pay Score
- **Conversion hooks**:
  - Your 4th invoice is waiting — unlock unlimited chasing for less than the cost of one late fee
  - One recovered invoice pays for Lifetime many times over
  - $0/month. Pay once. Yours forever. No subscription trap.

## Pro Features Unlocked (All Paid Tiers)

| Feature | Free | Pro (Lifetime / Monthly / Annual) |
|---------|:----:|:---------------------------------:|
| Active invoices | 3 | Unlimited |
| Escalation letters L0–L2 | ✅ | ✅ |
| Escalation letters L3–L5 (Firm / Formal Demand / Final Notice) | ❌ | ✅ |
| Late interest calculator | ❌ | ✅ |
| Formal Demand Letter PDF export | ❌ | ✅ |
| Home screen + lock screen widgets | ❌ | ✅ |
| Industry phrase packs | ❌ | ❌ Not included — separate $2.99 add-on each |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid subscription)
- **Available for**: PaidPulse Pro Annual ($9.99/year)

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation + restore instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription products exist)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView
- [x] Free trial terms included (7-day Annual trial)
- [x] Restore purchases functionality implemented
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] Differentiation notes present for same-feature tiers (Lifetime vs Monthly vs Annual)
- [x] Phrase pack add-ons scoped to content only, never listed as Pro unlocks
