# Lip Map

Joke map for nicotine pouch pins. Entertainment. 18+.

**Not** a quit app. Not wellness. Not Health & Fitness.

---

## Identity

| | |
|---|---|
| Display name | Lip Map |
| Bundle name | Lip Map |
| Bundle ID | `com.lipmap.app` |

Do **not** use the word ZYN in the app name, icon, paywall, or StoreKit product names. Internal joke only: badge **ZYNachino**. Optional splash text: “Lip Map”. Never “ZYNachino” as the app title.

---

## What this is

User taps one button when they put in a nicotine pouch. App drops a GPS pin. Friends share a 6-digit code and see pins. Entertainment only.

## What this is not

Do **not** add: savings, money wasted, taper, quit date, craving timer, gum health, daily limit, “stay strong”, HealthKit, nicotine mg charts, streak-for-quitting, camera of a can, social feed, comments, likes, AI, chat.

---

## Stack

- SwiftUI, iOS 17+
- MapKit
- CoreLocation (when-in-use only; requested on first tap of Tucked)
- SwiftData for local pins
- StoreKit 2 for subscriptions
- Friends: 6-digit code + CloudKit (prefer shipping; stub only if must)

---

## One primary action

Giant button labeled **Tucked**.

On tap: haptic → lat/long + timestamp → save Pin → drop on map → return home (button + today’s count).

Optional flavor after save: Cool Mint / Wintergreen / Other — skip if it slows first tap. Flavor optional; location not.

---

## Tabs (exactly 4)

1. **Home** — giant Tucked, today’s count, small last tuck time
2. **Map** — all my pins, cluster if needed, tap = time + optional flavor
3. **Badges** — locked/unlocked grid
4. **Friends** — 6-digit code, paste friend code, friends list, weekly league

No extra tabs, settings mazes, onboarding essays, streak calendar. One short permission sentence on first Tucked.

---

## League

Rank by **unique pin locations this week** (distinct rounded coords/places), **not** total pouches. Never “most tucks wins”. Personal today-count on Home only.

---

## Badges

Enum + simple unlock rules; no badge editor.

| Badge | Rule |
|---|---|
| ZYNachino | Coffee/cafe POI or tag “coffee” |
| Church Parking Lot | Church / parking near place of worship |
| Gate B12 | Airport |
| Her Parents’ House | Manual |
| 2:07 AM | Timestamp 2:00–2:59 AM |
| Two In One Red Light | Two pins within 3 minutes |
| Work Bathroom | Manual |
| Boat | Water / marina / boat-related place |
| Deer Stand | Manual |
| Upper Deck | Elevated / stadium upper-level tag |
| Interstate | Near highway / interstate |
| First One | First pin ever |

---

## Paywall (StoreKit 2)

| Product ID | Price | Notes |
|---|---|---|
| `lipmap_yearly` | $9.99 | Highlight; 3-day free trial; “83¢ a month” |
| `lipmap_monthly` | $1.99 | |

- Title: **Full Map**
- Body: All-time pins. Badges. Friends. Weekly location league.
- Restore Purchases.
- Hard paywall when **20 tucks** OR **7 days since first tuck** (whichever first).
- Free: last 7 days pins, no friends league, badges visible but locked art.

---

## Legal / privacy

- 18+
- Location usage string: “Lip Map drops a pin when you tap Tucked.”
- Location only on button tap
- No tobacco logos / can icon
- Icon: simple map pin on plain background

---

## App Store text

**Name:** Lip Map

**Subtitle:** Pouch Pins

**Description:**

Lip Map is a joke map for pouch people. Tap Tucked when you put one in. We drop a pin. That’s the whole bit.

Share a 6-digit code with friends, peek at their pins, and climb a weekly league ranked by unique places — not volume. Unlock ridiculous badges like ZYNachino, Gate B12, and Two In One Red Light.

Entertainment only. 18+. Not a quit app. Not wellness. Just pins.

**Keywords:** pouch,map,pins,friends,joke,league,badges,location,entertainment,social

---

## Ship order

1. Tucked + local pins + map + today count
2. Badges
3. StoreKit both products
4. Friends

---

## Project layout

```
LipMap/
  LipMap/           # app sources
  LipMap.xcodeproj
  LipMapTests/
  README.md
```

Open `LipMap.xcodeproj` on a Mac with Xcode 15+ (iOS 17 SDK). Linux hosts cannot compile or run the iOS target.
