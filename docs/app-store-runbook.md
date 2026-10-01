# Lip Map — App Store submit runbook

Step-by-step for Mike after the prep docs land on `master`.  
This does **not** enroll you in the Apple Developer Program — complete paid enrollment yourself if it isn’t already active.

Related docs in this folder:

- [app-store-listing.md](./app-store-listing.md) — name, subtitle, description, keywords  
- [app-store-iap.md](./app-store-iap.md) — `lipmap_yearly` / `lipmap_weekly`  
- [app-store-screenshots.md](./app-store-screenshots.md) — what to capture  
- [privacy.html](./privacy.html) — privacy policy page  
- [github-pages.md](./github-pages.md) — stable privacy URL  

---

## 0. Preconditions (manual)

- [ ] **Paid** Apple Developer Program team (not only Personal Team) for the signing identity you will ship with  
- [ ] App Store Connect access for that team  
- [ ] Paid Apps Agreement + banking + tax cleared (needed for IAP)  
- [ ] Mac with Xcode 15+ / current stable, project opens from latest `master`  
- [ ] Privacy URL live: `https://msmglobal-construction.github.io/lip-map/privacy.html`  
  - Interim: `https://raw.githubusercontent.com/msmglobal-construction/lip-map/master/docs/privacy.html`

```bash
cd /path/to/lip-map   # or git clone https://github.com/msmglobal-construction/lip-map.git
git pull origin master
open LipMap.xcodeproj
```

---

## 1. Signing & capabilities

1. Xcode → target **Lip Map** → Signing & Capabilities  
2. Team: **paid** organization/individual team (not free Personal Team for App Store archive)  
3. Bundle ID: `com.lipmap.app` — register the App ID in the Developer portal if missing  
4. Confirm entitlements match what you intend to ship (empty / no iCloud is OK for a local-first 1.0; enable CloudKit only if provisioned)  
5. Release configuration builds clean on a device or Simulator  

---

## 2. Version bump

- [ ] Marketing version **1.0** (or your chosen first version)  
- [ ] Build number unique (e.g. `1`)  
- [ ] Run unit tests: Product → Test  

---

## 3. Archive & upload

1. Select **Any iOS Device (arm64)** (not a Simulator)  
2. Product → **Archive**  
3. Organizer → **Distribute App** → **App Store Connect** → Upload  
4. Wait for processing email / ASC **TestFlight** build to appear  

---

## 4. Create the App Store Connect record (once)

1. My Apps → **+** → New App  
2. Platforms: iOS  
3. Name: **Lip Map**  
4. Primary language: English (U.S.)  
5. Bundle ID: `com.lipmap.app`  
6. SKU: `lipmap`  
7. User access: Full Access (unless you need limited)

---

## 5. Metadata (from listing doc)

Paste from [app-store-listing.md](./app-store-listing.md):

- [ ] Name: Lip Map  
- [ ] Subtitle: Pouch Pins  
- [ ] Privacy Policy URL (Pages URL preferred)  
- [ ] Category: **Entertainment**  
- [ ] Age rating questionnaire → **17+** (nicotine-related)  
- [ ] Description, keywords, promotional text, What’s New  
- [ ] Support URL  
- [ ] App icon (1024) — export from locked v5 pillow+pin asset; no ZYN text  

---

## 6. App Privacy (nutrition labels)

Declare only what the app actually uses:

| Data type | Linked to user? | Used for tracking? | Notes |
|---|---|---|---|
| Location | No (on-device pins) / Yes if you sync with account — be honest for CloudKit | **No** | Collected when user taps Tucked; When In Use |
| Contacts | No | **No** | Optional invite picker only |
| Purchases | Yes (Apple) | **No** | StoreKit subscriptions |

- Tracking: **No**  
- HealthKit: **not used** — do not declare health data  

---

## 7. In-App Purchases

Follow [app-store-iap.md](./app-store-iap.md):

- [ ] Group **Full Map**  
- [ ] `lipmap_yearly` $9.99 + 3-day free trial  
- [ ] `lipmap_weekly` $0.99  
- [ ] Products selected on this version  
- [ ] Sandbox purchase smoke-test  

---

## 8. Screenshots

Follow [app-store-screenshots.md](./app-store-screenshots.md):

Home/Tucked · Map · Badges · Friends leaderboard · Paywall · Dashboard  

---

## 9. Review notes (paste into ASC)

```
Lip Map is an entertainment joke-map for adults (18+; App Store 17+) about nicotine pouch “lip pillows.” It is NOT a quit, wellness, or Health & Fitness app. No HealthKit. No advertising tracking.

Location: When In Use only. Purpose string: “Lip Map drops a pin when you tap Tucked.” Location is requested on the first Tucked tap to save a map pin. No background location.

Contacts: Optional — used only if the user invites friends via the contact picker.

IAP: Auto-renewable subscriptions in group “Full Map”:
- lipmap_yearly — $9.99/year with 3-day free trial
- lipmap_weekly — $0.99/week
Hard paywall after 20 tucks OR 7 days since first tuck. Free tier keeps last 7 days of pins. Restore Purchases is on the paywall.

Demo:
1. Launch → Home → tap Tucked → allow Location → pin saved.
2. Map tab shows pin(s).
3. Badges tab shows progress.
4. Friends tab shows weekly unique-places leaderboard; invite is optional.
5. Home → Your map stats opens the dashboard sheet.
6. After free gate, paywall offers yearly/weekly; Restore available.

No account login required for core pinning on device.
```

---

## 10. Submit for Review

1. Select the processed build  
2. Export compliance: standard encryption / HTTPS-only answers as applicable  
3. Advertising Identifier: **No**  
4. Submit  

---

## After submit

- Watch Resolution Center for questions about nicotine framing, location, or IAP  
- If rejected for age rating, tighten 17+ questionnaire + review notes (entertainment, not sales of tobacco)  
- LeaveNow / other repos: untouched — this runbook is Lip Map only  

---

## Quick link checklist

| Item | URL / path |
|---|---|
| Repo | https://github.com/msmglobal-construction/lip-map |
| Privacy (Pages) | https://msmglobal-construction.github.io/lip-map/privacy.html |
| Privacy (interim raw) | https://raw.githubusercontent.com/msmglobal-construction/lip-map/master/docs/privacy.html |
| Listing copy | `docs/app-store-listing.md` |
| IAP | `docs/app-store-iap.md` |
| Screenshots | `docs/app-store-screenshots.md` |
