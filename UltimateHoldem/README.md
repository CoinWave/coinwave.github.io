# Ultimate Poker: Hold’em Casino (iOS)

A native SwiftUI Ultimate Texas Hold'em table game with a progressive jackpot, built in the style of the "Three Card Poker" social-casino apps: red lobby, table carousel that unlocks by level, chip store, daily wheel.

**Features**
- Full Ultimate Texas Hold'em: Ante = Blind, optional Trips and Progressive side bets, Play 4x/3x preflop, 2x on the flop, 1x or fold on the river, dealer qualifies with a pair.
- Progressive jackpot meter (Royal Flush = 100%, Straight Flush = 10%, fixed pays for Quads down to Trips, on hole cards + flop).
- Free welcome chips on sign-up (first launch: pick a name, claim 1,000,000 chips).
- Daily bonus wheel: one free spin every 24h, prizes 20,000 – 2,000,000 (weighted so big prizes are rare).
- Chip store with 6 pack levels ($0.99 – $49.99) using StoreKit 2.
- Promo code box in the store: a valid code adds a bonus % to the next pack purchased. Codes are built into the app (no server).
- Levels/XP, level-up chip rewards, 6 table stakes unlocking at levels 1, 5, 15, 30, 50, 75.
- Rules & Payouts popup (gold button at the top of the lobby, the PAYOUTS tile, and the ⓘ on the table) with every paytable on one screen, plus a full written rules page.
- Stats and settings (haptics, fast deal, restore purchases).
- App Store name: **Ultimate Poker: Hold’em Casino**; home-screen name: **Ultimate Poker** (iOS cuts off long names under the icon).
- Landscape only, iPhone (runs on iPad in iPhone mode). No third-party dependencies.

## 1. Open it in Xcode

You need a Mac with Xcode 26 or later. No Terminal or extra tools are needed.

1. Unzip `UltimateHoldem.zip` (double-click it in Finder).
2. Open the `UltimateHoldem` folder and double-click **`UltimateHoldem.xcodeproj`** (the blue icon).
3. In the left sidebar, click the blue **UltimateHoldem** project at the top → under TARGETS pick **UltimateHoldem** → **Signing & Capabilities** tab.
4. Check **Automatically manage signing**, pick your **Team** (add your Apple ID first in Xcode → Settings → Accounts if the list is empty), and change **Bundle Identifier** to something unique like `com.blakeshuert.ultimatepoker`.
5. Click **+ Capability** and add **In-App Purchase**.
6. At the top of the window, choose an iPhone simulator (e.g. iPhone 17 Pro) and press **⌘R** (or the ▶︎ button).

Purchases work in the simulator right away through `Configuration/Products.storekit`. If the store says items aren't available, open Product → Scheme → Edit Scheme → Run → Options and set **StoreKit Configuration** to `Products.storekit`.

Run the tests with ⌘U (hand rankings, payouts, dealer qualification, folds, jackpot, wheel landing, chip pack value).

`project.yml` is only there if you ever want to regenerate the project with XcodeGen; you don't need it.

## 2. Change these before shipping

All tunable values are in `UltimateHoldem/Config/GameConfig.swift`:

| What | Setting |
|---|---|
| Sign-up bonus | `welcomeBonus` |
| Wheel prizes & odds | `wheelSegments` (amount, weight, color) |
| Table stakes & unlock levels | `tables` |
| Jackpot seed / growth | `jackpotSeed`, `jackpotContribution` |
| Chip packs (IDs, chips, bonus %) | `chipPacks` |
| Privacy policy / terms | `privacyPolicyURL`, `termsURL` |

If you change the bundle ID, also find-and-replace `com.yourname.ultimateholdem` in `GameConfig.swift` and `Configuration/Products.storekit` so the product IDs match.

Payout tables live in `UltimateHoldem/Engine/Paytables.swift`.

## 3. Promo codes (built in)

Codes live in `UltimateHoldem/Resources/promo_codes.json`. To add or expire codes, edit that file and submit an app update. No server is involved.

```json
{
  "codes": [
    { "code": "WELCOME25", "bonusPercent": 25, "oncePerPlayer": true, "label": "Welcome! +25% bonus chips" },
    { "code": "HOLIDAY50", "bonusPercent": 50, "expires": "2026-12-31",
      "minProductID": "com.yourname.ultimateholdem.chips.tier3" }
  ]
}
```

- `bonusPercent`: extra chips as a % of the pack bought.
- `expires` (optional): last valid day, `yyyy-MM-dd`. Handy since you can't change codes without an update.
- `oncePerPlayer` (optional, default true).
- `minProductID` (optional): only works on that pack or bigger.


## 4. App Store Connect

1. Create the app record (bundle ID must match).
2. **In-App Purchases** → create 6 **Consumable** products with exactly these IDs and prices:

| Product ID | Price | Chips |
|---|---|---|
| `…chips.tier1` | $0.99 | 2,000,000 |
| `…chips.tier2` | $4.99 | 10,000,000 + 20% = 12M |
| `…chips.tier3` | $9.99 | 20,000,000 + 50% = 30M (MOST POPULAR) |
| `…chips.tier4` | $19.99 | 40,000,000 + 75% = 70M |
| `…chips.tier5` | $29.99 | 60,000,000 + 100% = 120M |
| `…chips.tier6` | $49.99 | 100,000,000 + 150% = 250M (BEST VALUE) |

   Each needs a display name, description and a review screenshot of the store screen. Submit them with the first build.
3. **Age rating**: answer "Frequent/Intense" for *Simulated Gambling* → the app will be rated 17+. Answer "No" to real-money gambling.
4. **App Privacy**: the app collects no data (chips and progress are stored on-device). A privacy policy URL is still required.
5. Category: Games → Casino.
6. Archive in Xcode (Product → Archive) → Distribute → App Store Connect → submit for review.

### App Review notes
- Simulated gambling is allowed because chips can never be cashed out or exchanged for prizes. Keep it that way; the disclaimers are already in the welcome, store and settings screens.
- Casino apps often get rejected under guideline 4.3 (spam / copycat) if they look like a template. Use your own name, icon and art before submitting; the bundled icon is a placeholder.
- No "Remove Ads" item is included because the app has no ads. Selling one without ads would be rejected.

## 4a. Listing text, support page & privacy policy

- `AppStoreAssets/AppStoreListing.txt`: every App Store Connect field ready to paste: name, subtitle, promotional text, keywords, description, age-rating answers, App Privacy answer, App Review notes, and in-app purchase names.
- `AppStoreAssets/ultimate-poker/`: `support.html`, `privacy.html` and `icon.png` (support email: dimaseoinc@gmail.com). They're hosted with GitHub Pages:
  1. Rename the GitHub repo `CoinWave/github.io` to **`CoinWave.github.io`** (repo → Settings → Repository name). GitHub only serves `https://coinwave.github.io/` from a repo with that exact name.
  2. In the repo, click **Add file → Upload files**, drag in the `ultimate-poker` folder (from `AppStoreAssets/`), and click **Commit changes**.
  3. Repo → Settings → **Pages** → Source: **Deploy from a branch**, Branch: **main**, folder **/(root)** → Save. After a minute or two the pages are live at:
     - Support: https://coinwave.github.io/ultimate-poker/support.html
     - Privacy: https://coinwave.github.io/ultimate-poker/privacy.html

## 4b. Icon & screenshots

`AppStoreAssets/` holds:
- `AppIcon-1024.png` (light), `AppIcon-Dark-1024.png`, `AppIcon-Tinted-1024.png`. All three are already in the asset catalog, so iOS 18 dark and tinted home screens use the right one. They follow Apple's icon guidelines: full-bleed square, no transparency on the main icon, no baked-in rounded corners, no text (the app name shows under the icon).
- `Screenshot-iPhone-6.9in-2868x1320.png`: a table image at the required 6.9" iPhone size, for placeholder/marketing use.

Before submitting, replace the placeholder screenshot with real ones. Apple requires screenshots to show the app actually in use: run the app in the iPhone 16 Pro Max simulator and press ⌘S to save them at the right size.

## 4c. Free chips for testing

The app has no sign-in, so it can't recognize a tester by email. Two built-in ways to get free chips:
- **TestFlight:** in App Store Connect → TestFlight, add testers by email (e.g. yours). Purchases in TestFlight builds use Apple's sandbox and are never charged, so testers can "buy" any pack for free.
- **Tester tools:** when you run from Xcode (Debug build), Settings shows a *Tester tools* section: +10M / +100M chips, reset the daily wheel, unlock all tables. It's compiled out of TestFlight and App Store builds, so the public app never contains it.

## 5. How it works today (and upgrade paths)

- **Jackpot is per device.** It grows from that player's own progressive bets. For one shared jackpot across all players you'd add a backend (e.g. Firebase) and replace `JackpotStore` — the rest of the app only calls `contribute`, `pay` and reads `amount`.
- **Chips are stored on the device** (UserDefaults). Deleting the app resets them. Syncing across devices would need iCloud or an account backend.
- **Visit counting is on the device.** Deleting the app resets it.
- **Daily wheel timing uses the device clock**, so a player could move their clock forward to spin early. A server timestamp fixes that if it matters.
- Purchases are verified by StoreKit 2 on-device and each transaction is credited exactly once.

## Project layout

```
UltimateHoldem/
  App/            app entry, root routing (welcome vs lobby)
  Config/         GameConfig — every tunable number
  Engine/         cards, hand evaluator, paytables, settlement, table state machine, wheel
  Services/       player wallet/levels, jackpot, StoreKit store, promo codes
  Views/          lobby, table, store, wheel, welcome, rules, settings, shared components
  Resources/      asset catalog (icon), promo_codes.json, privacy manifest
UltimateHoldemTests/   unit tests for the rules engine
Configuration/Products.storekit   local StoreKit test products
project.yml       XcodeGen spec
```
