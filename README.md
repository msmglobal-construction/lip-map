# Lip Map

Joke map for nicotine pouch pins (“lip pillows”). Entertainment. 18+.

**Not** a quit app. Not wellness. Not Health & Fitness.

---

## Identity

| | |
|---|---|
| Display name | Lip Map |
| Bundle name | Lip Map |
| Bundle ID | `com.lipmap.app` |

Do **not** use the word ZYN in the app name, icon, paywall, or StoreKit product names. Internal joke badges only: **ZYNachino**, **Zynbabwe**. Optional splash text: “Lip Map”.

**App icon (locked):** white lip pillow + red map pin (`docs/lip-map-app-icon-v5.png` → `AppIcon.appiconset`). No can. No ZYN text. Not v1 lips / v2 sunglasses.

---

## What this is

User taps **Tucked** when they put in a lip pillow. App drops a GPS pin, optionally tags flavor, reverse-geocodes state/city. Friends invite via Contacts + deep link. Weekly league = unique places, not tuck volume. Entertainment only.

## What this is not

Do **not** add: savings, money wasted, taper, quit date, craving timer, gum health, daily limit, “stay strong”, HealthKit, nicotine mg charts, streak-for-quitting, camera of a can, social feed, comments, likes, AI, chat.

---

## Stack

- SwiftUI, iOS 17+
- MapKit
- CoreLocation (when-in-use only; requested on first tap of Tucked)
- CLGeocoder for state / locality (background after tuck)
- SwiftData for local pins
- StoreKit 2 for subscriptions
- Friends: Contacts invite + `lipmap://` deep link (6-digit code = fallback) + CloudKit preferred

---

## One primary action

Giant button labeled **Tucked**.

On tap: haptic → lat/long + timestamp → save Pin → drop on map → return home (button + today’s count). Optional flavor sheet after save — never blocks the primary tap. Region geocode + POI tags run in background.

---

## Tabs (exactly 4)

1. **Home** — giant Tucked, today + lifetime counts, chips for **Your map stats** (dashboard), **States**, **History** (swipe-delete). No 5th tab.
2. **Map** — pins, callout with flavor/place + delete
3. **Badges** — locked/unlocked grid (flavor + state + place jokes)
4. **Friends** — **leaderboard first** (unique places this week), Contacts invite / share link, Accept/Decline, code fallback

---

## Flavors

Optional after Tucked. Persist on pin. Menu (brand-agnostic names): Cool Mint, Spearmint, Peppermint, Menthol, Wintergreen, Peppermint Ice, Citrus, Lemon, Lime, Orange, Coffee, Espresso, Chill, Smooth, Black Cherry, Apple Mint, Vanilla, Dragon Fruit, Other.

Flavor badges: First Cool Mint, Flavor Tourist (5), Full Flight (10), Mint Machine (5 mint-family).

---

## States

Pins store `regionCode` / `regionName` / `locality` from reverse geocode. Home → States shows US states (+ DC) grid of where you’ve lip pillow’d. Badge **Zynbabwe** at 5 states.

---

## Delete tuck

Swipe-delete in Home → History, or trash on Map pin callout. Removes SwiftData pin; counts, map, badges, states, league recompute from remaining pins.

---

## Dashboard (Home sheet)

Joke-map stats only: lifetime / week / unique places, time-of-day + day-of-week heat, top places/states, flavor breakdown. **Not** quit/wellness (no money saved, no cut-back).

---

## Friends & leaderboard

- Primary: **Invite from Contacts** → Messages/share sheet with `lipmap://invite?code=XXXXXX`
- Fallback: typed 6-digit code
- Follow request → peer Accept before follow/pins
- **Leaderboard** is the top Friends section: rank, name, unique-place count this week among you + accepted friends. Never “most tucks wins”.

---

## League

Rank by **unique pin locations this week** among **accepted follows only**. Home shows today-count plus **lifetime** tuck count.

---

## Badges

| Badge | Rule |
|---|---|
| ZYNachino | Coffee/cafe POI or Coffee/Espresso flavor |
| Church Parking Lot | Church / parking near place of worship |
| Gate B12 | Airport |
| Her Parents’ House | Manual |
| 2:07 AM | Timestamp 2:00–2:59 AM |
| Two In One Red Light | Two pins within 3 minutes |
| Work Bathroom | Manual |
| Boat | Water / marina |
| Deer Stand | Manual |
| Upper Deck | Stadium / upper level |
| Interstate | Highway |
| First Lip Pillow | 1 lifetime tuck |
| Ten Deep / Fifty Deep / Hundred Club | 10 / 50 / 100 lifetime |
| First Cool Mint | Cool Mint flavor |
| Flavor Tourist / Full Flight | 5 / 10 distinct flavors |
| Mint Machine | 5 mint-family tucks |
| Zynbabwe | 5 US states |

---

## Paywall (StoreKit 2)

| Product ID | Price | Notes |
|---|---|---|
| `lipmap_yearly` | $9.99 | Primary; 3-day free trial; “19¢ a week” |
| `lipmap_weekly` | $0.99 | Secondary; no trial |

- Title: **Full Map**
- Hard paywall: **20 tucks** OR **7 days since first tuck**
- Free: last 7 days pins; league locked
- No monthly. No ZYN in product display names.

---

## Legal / privacy

- 18+
- Location: “Lip Map drops a pin when you tap Tucked.”
- Contacts: “Lip Map uses Contacts so you can invite friends to compare unique places — entertainment only.”
- URL scheme: `lipmap://`
- **Privacy Policy (public):** https://msmglobal-construction.github.io/lip-map/privacy.html  
  - Source: [`docs/privacy.html`](docs/privacy.html) · Markdown: [`docs/privacy.md`](docs/privacy.md)  
  - Pages setup: [`docs/github-pages.md`](docs/github-pages.md)  
  - Interim (pre-Pages): https://raw.githubusercontent.com/msmglobal-construction/lip-map/master/docs/privacy.html

---

## App Store submission

Ship checklist for Mike: **[`docs/app-store-runbook.md`](docs/app-store-runbook.md)**

| Doc | Purpose |
|---|---|
| [app-store-runbook.md](docs/app-store-runbook.md) | Paid team → Archive → upload → ASC metadata → review notes |
| [app-store-listing.md](docs/app-store-listing.md) | Name, subtitle, description, keywords, What’s New |
| [app-store-iap.md](docs/app-store-iap.md) | `lipmap_yearly` / `lipmap_weekly` + ASC steps |
| [app-store-screenshots.md](docs/app-store-screenshots.md) | Home, Map, Badges, Friends, Paywall, Dashboard |

Age rating target: **17+** (nicotine-related entertainment). No ZYN in listing or IAP display names.

---

## Mac setup

```bash
git pull origin master
open LipMap.xcodeproj
```

Xcode 15+ (iOS 17 SDK). Pick a Personal Team, run on simulator or device. Linux hosts cannot compile the iOS target.

Personal Team signing: entitlements stay empty (no iCloud). CloudKit later with paid Apple Developer Program.

---

## Project layout

```
LipMap/
  LipMap/           # app sources
  LipMap.xcodeproj
  LipMapTests/
  docs/             # icon (v5 locked), privacy, App Store prep
  README.md
```
