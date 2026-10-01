# Lip Map — App Store listing copy

Paste into App Store Connect. Do **not** put “ZYN” in the name, subtitle, promotional text, or IAP display names.

| Field | Value |
|---|---|
| **Name** (30) | Lip Map |
| **Subtitle** (30) | Pouch Pins |
| **Category** | Entertainment (primary). Do **not** use Health & Fitness. |
| **Age rating** | **17+** (nicotine-related content / mature themes). Confirm questionnaire answers for tobacco/nicotine references. |
| **Privacy Policy URL** | `https://msmglobal-construction.github.io/lip-map/privacy.html` |
| **Support URL** | GitHub Issues for now: `https://github.com/msmglobal-construction/lip-map/issues` (replace with a support email page if you prefer) |
| **Marketing URL** | Optional — leave blank for 1.0 |
| **Bundle ID** | `com.lipmap.app` |
| **SKU** | e.g. `lipmap` |

---

## Promotional Text (170)

Drop a pin every time you tuck. Map your places, unlock joke badges, and race friends on unique spots — entertainment for adults 18+.

---

## Description

**Lip Map** is a joke map for nicotine pouch pins — your “lip pillows” on a map.

Tap **Tucked** when you put one in. Lip Map drops a GPS pin, optionally lets you tag a flavor, and builds a personal map of where you’ve been. Unlock silly badges. Invite friends and compete on **unique places** this week — not who tucked the most.

This is entertainment. It is **not** a quit app, wellness coach, or Health & Fitness tracker. No savings counters. No cravings. No HealthKit.

**Features**
- Giant **Tucked** button — one tap to pin
- Optional brand-agnostic flavors after you tuck
- Map of your pins with place callouts
- Joke badges (coffee shop energy, late-night pins, state counts, and more)
- Friends invites via Contacts + share link
- Weekly leaderboard ranked by unique places
- Dashboard joke-stats (time-of-day heat, top places, flavors)
- Full Map subscription for all-time pins, badges, friends league, and more

**Age**
18+ only. Nicotine products are addictive and not for minors. App Store age rating: 17+.

**Location**
Location is used only when you tap Tucked (When In Use) so we can drop your pin.

**Subscriptions**
Full Map unlocks the complete experience. See the paywall for yearly (with free trial) and weekly options. Manage or cancel in Apple ID → Subscriptions.

---

## Keywords (100 characters max, comma-separated, no spaces after commas preferred)

```
pouch,nicotine,map,pins,lip,pillow,friends,badges,leaderboard,tuck,places,joke
```

Count check: keep under 100 characters including commas. Adjust if ASC rejects length.

Suggested trimmed set if needed:

```
pouch,nicotine,map,pins,lip,pillow,friends,badges,tuck,places,joke
```

---

## What’s New (1.0)

Welcome to Lip Map — drop a pin when you tuck, unlock joke badges, invite friends, and compete on unique places. Entertainment for adults 18+.

---

## Review notes (short version — full script in app-store-runbook.md)

- Entertainment joke-map; not quit/wellness; 17+ / 18+ framing for nicotine pouch humor.
- Location: When In Use only; purpose string: “Lip Map drops a pin when you tap Tucked.”
- Contacts: optional invites only.
- IAP: auto-renewable `lipmap_yearly` ($9.99, 3-day trial) and `lipmap_weekly` ($0.99).
- No tracking / no HealthKit.
- Demo: tap Tucked → allow location → pin on Map; open Badges, Friends leaderboard, Paywall, Home dashboard sheet.

---

## Naming rules (do not break)

- Product / listing names: **Lip Map**, subtitle **Pouch Pins**, paywall **Full Map**, products **Full Map Yearly / Weekly**.
- Never use ZYN in App Store name, subtitle, promo text, screenshots text overlays, or StoreKit product display names.
- Internal joke badges (ZYNachino, Zynbabwe) may appear in-app; do not feature those brand-adjacent strings in store marketing copy.
