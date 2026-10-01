# Lip Map — In-App Purchase checklist

Match StoreKit config in `LipMap/Resources/Products.storekit` and `EntitlementStore.swift`.

## Products to create in App Store Connect

Create an **Auto-Renewable Subscription** group named **Full Map**, then add:

| Product ID | Reference name | Duration | Price (US) | Introductory offer |
|---|---|---|---|---|
| `lipmap_yearly` | Full Map Yearly | 1 year | **$9.99** | **3-day free trial** (free, 1 period, P3D) |
| `lipmap_weekly` | Full Map Weekly | 1 week | **$0.99** | None |

Display names (localization en-US):

| Product ID | Display name | Description |
|---|---|---|
| `lipmap_yearly` | Full Map Yearly | Full Map yearly. About 19¢ a week. |
| `lipmap_weekly` | Full Map Weekly | Full Map weekly. |

Subscription group localization:

- Display name: **Full Map**
- Description: All-time pins, badges, friends, and weekly location league.

**Do not** put ZYN in any product ID, reference name, or display name.  
**Do not** add a monthly SKU for 1.0.

Family Sharing: **off** (matches local StoreKit config `familyShareable: false`) unless you consciously change the app later.

---

## App Store Connect steps

1. Paid Apple Developer Program membership active (required for IAP + App Store).
2. App Store Connect → **My Apps** → Lip Map (create app if needed: bundle `com.lipmap.app`).
3. **Monetization** → **Subscriptions** → **+** subscription group → name **Full Map**.
4. Add `lipmap_yearly`:
   - Duration: 1 Year
   - Price: $9.99 (or Tier matching $9.99)
   - Introductory Offer → Free → 3 Days → qualifying: new subscribers (default)
   - Localization display name / description as above
5. Add `lipmap_weekly`:
   - Duration: 1 Week
   - Price: $0.99
   - No intro offer
6. Attach both products to the app version’s **In-App Purchases and Subscriptions** section before submit.
7. Complete **Paid Applications Agreement**, banking, and tax in ASC **Business** / Agreements — IAP will stay “Missing Metadata” / unavailable until this is clear.
8. Add App Review screenshot for the subscription if ASC requires one (paywall screen is fine).
9. Review subscription **Review Notes**: hard paywall after 20 tucks OR 7 days since first tuck; free users see last 7 days of pins; Restore Purchases on paywall.

---

## Local / Sandbox testing (Mac)

1. Xcode → Scheme → Run → Options → StoreKit Configuration → `Products.storekit`
2. Or use Sandbox Apple ID on device (Settings → Developer / App Store sandbox).
3. Verify:
   - [ ] Yearly shows trial copy and unlocks after purchase
   - [ ] Weekly unlocks without trial
   - [ ] Restore Purchases works
   - [ ] Gate still fires at 20 tucks / 7 days when unsubscribed

---

## App binary alignment

| Code constant | Value |
|---|---|
| `EntitlementStore.yearlyProductID` | `lipmap_yearly` |
| `EntitlementStore.weeklyProductID` | `lipmap_weekly` |
| Paywall title | Full Map |
| Yearly marketing | $9.99/year · 19¢ a week · 3-day free trial |
| Weekly marketing | $0.99/week |

If ASC product IDs differ, the app will not load products — keep IDs identical.
