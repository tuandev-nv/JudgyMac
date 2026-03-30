# JudgyMac — Master Plan

> Menu bar app macOS — MacBook has opinions about your life choices.
> **Model**: Freemium + IAP Packs + Pro Subscription
> **Target**: macOS 14+ (Sonoma), Apple Silicon
> **Tech**: Swift 6 + SwiftUI + StoreKit 2

---

## 1. Product Vision

### One-liner
"Your Mac watches everything you do — and judges you for it."

### Concept
MacBook theo doi hanh vi su dung va "roast" ban qua notification va menu bar dropdown.
Khong giong SlapMac (tat may → keu), JudgyMac la **behavioral companion** — theo doi pattern hang ngay va roast bang text co personality.

### Competitive Positioning

```
SlapMac  = Physical gag toy (tat → keu)        → One-time fun
JudgyMac = Behavioral AI companion (judge 24/7) → Daily engagement
```

SlapMac viral (#1 Product Hunt, 469 upvotes, $7) validate rang "fun Mac menu bar app" co demand cuc lon.
JudgyMac sau hon, retention tot hon, monetize tot hon.

### SlapMac Deep Analysis — Evolving Threat

SlapMac KHONG chi la "tat → keu" nua. No dang update lien tuc:

```
v1.0:   Slap detection → scream (1 trigger)
v1.1:   + USB Moaner mode (cam/rut USB → keu)
v1.1.2: + Decoupled soundpacks, settings overhaul
v1.2:   Custom sound pack creation (coming)
v1.3:   Local MCP server — AI integration (coming)
Future: SlapPhone (iOS version)
```

**Overlap dang tang**: SlapMac mo rong tu 1 trigger → nhieu triggers vat ly.
Nhung **core difference van ro rang**:

| Dimension | SlapMac | JudgyMac |
|-----------|---------|----------|
| **Input type** | Physical impact (accelerometer) | Behavioral pattern (software) |
| **Output type** | Sound effects (no meaning) | Text with personality (contextual) |
| **Intelligence** | Reflexive: trigger → sound | Context-aware: count, time, pattern |
| **Character depth** | Sound packs (no personality) | Named characters with voice, culture, humor style |
| **Content format** | Audio (need video to share) | Text (screenshot = instant share) |
| **Retention model** | Novelty decay (fun → boring) | Content refresh (new roasts daily) |
| **Engagement loop** | React once → done | Daily summary → streak → share → return |
| **Cultural depth** | Generic sounds | Culture-specific humor (Vietnamese Mom, Shakespeare) |

### Competitive Moat — What SlapMac CAN'T Copy

1. **Context-aware text**: "Lan thu 7 hom nay" vs generic sound — requires entirely different architecture
2. **Cultural personality system**: Vietnamese Mom's "con nha nguoi ta" is NOT translatable to sounds
3. **Shareable text content**: Text screenshots go viral; sound recordings don't
4. **Daily narrative arc**: Summary cards tell a story; sounds have no memory
5. **Template/content engine**: 80+ roasts per personality with variables — this is a content moat

### Positioning Strategy

```
DON'T compete on: triggers (SlapMac will always add more physical triggers)
DO compete on:    personality, context, text, shareability, cultural humor, retention

Tagline contrast:
  SlapMac  → "Your Mac screams when you hit it"
  JudgyMac → "Your Mac has OPINIONS about your life choices"
```

### Co-Marketing Opportunity

SlapMac users = perfect JudgyMac target audience.
Marketing angle: "Liked SlapMac? What if your Mac didn't just scream — it actually JUDGED you?"

---

## 2. Target Market — International First

### Why International (English-First)?

```
Vietnam Mac users:     ~500K (tiny, low willingness to pay for apps)
US Mac users:          ~30M (highest app spending per capita)
Global Mac users:      ~100M
Global English speakers with Mac: ~50M+
```

> Thi truong Viet Nam KHONG DU de kiem $100K.
> Phai target US, UK, Canada, Australia, EU lam primary market.
> Vietnamese Mom pack la viral hook, KHONG phai primary language.

### Market Tiers

| Tier | Market | Mac Users | Willingness to Pay | Language Priority |
|------|--------|-----------|--------------------|--------------------|
| **1 (Primary)** | US, Canada, UK, Australia | ~35M | Very High ($3-10 for apps) | English |
| **2 (Secondary)** | Germany, France, Netherlands, Nordics | ~10M | High | English (they use EN apps) |
| **3 (Growth)** | Japan, Korea | ~8M | High (strong app culture) | Japanese, Korean (localize later) |
| **4 (Viral niche)** | Vietnam, SEA | ~2M | Low | Vietnamese (Vietnamese Mom pack) |

### Language & Content Strategy

```
MVP LAUNCH — English only:
├── UI: English
├── "The Critic" personality: English (80+ roasts)
├── Landing page: English
├── App Store listing: English
├── TikTok content: English (target US audience)
└── Product Hunt: English

WEEK 2 — Add Vietnamese Mom pack:
├── Pack content: Vietnamese (50+ roasts)
├── App UI: remains English (Vietnamese users read EN UI fine)
├── TikTok: Vietnamese Mom specific content → viral in Asian community
└── This pack is a MARKETING TOOL, not the primary product

MONTH 2 — Localize for high-value markets:
├── Japanese: UI + 1 personality pack (localize humor, NOT translate)
├── Korean: UI + 1 personality pack
├── Spanish: 1 personality pack
└── App Store listing localized for top 5 markets

MONTH 3+ — Community-driven:
├── Open personality pack format for community contributions
├── German, French, Portuguese, etc.
└── Each market gets culture-specific humor (NOT translations)
```

### App Store Optimization (ASO) — English Keywords

```
Primary keywords:
  "mac menu bar app" "fun mac app" "productivity humor"
  "roast app" "judgy app" "sarcastic notifications"
  "mac personality app" "screen time roast"

Competitor keywords:
  "carrot weather alternative" "slapmac alternative"
  "funny mac utility" "mac desktop pet"

Long-tail:
  "app that judges your screen time"
  "mac app that roasts you"
  "sarcastic mac notifications"
```

### App Store Listing — English

```
Title: JudgyMac — Your Mac Judges You
Subtitle: Sarcastic notifications for your bad habits

Description:
Your MacBook is watching. It knows you opened that lid 7 times today.
It noticed you typing at 120 WPM like someone hurt you.
It saw you sitting idle for 47 minutes.

And it has OPINIONS.

JudgyMac is a menu bar companion that monitors your behavior and
delivers brutally honest commentary via macOS notifications.

Features:
• 7 behavior triggers (lid open, idle, overheating, late night...)
• Multiple personality modes (The Critic, Toxic Boss, Drill Sergeant...)
• Daily "Roast Summary" card — share with friends
• Beautiful dark UI with animated mood face
• Adjustable intensity — from gentle nudge to brutal roast

Free to download. Personality packs available as in-app purchases.
```

### Pricing — Localized by Region

| Region | Pack Price | Pro Yearly | Reasoning |
|--------|-----------|------------|-----------|
| US/UK/CA/AU | $1.99 | $9.99 | Standard pricing |
| EU (Eurozone) | €1.99 | €9.99 | Match dollar perception |
| Japan | ¥300 | ¥1,500 | JP users expect round yen numbers |
| Korea | ₩2,500 | ₩12,000 | KR app market norms |
| SEA/Vietnam | $0.99 | $4.99 | Lower purchasing power |

> Apple cho phep set gia khac nhau theo region trong App Store Connect.

### Marketing — International Focus

**TikTok (English-first)**
```
Account 1: @judgymac — main brand, EN content
  "POV: your Mac starts judging your life choices"
  "Things my MacBook said to me at 3am"
  "My Mac called me a serial procrastinator"

Account 2: @judgymac.vn — Vietnamese niche
  "Vietnamese Mom mode is BRUTAL"
  "Khi MacBook biet ban la con nha nguoi ta"
  → This is the viral wildcard — Asian parent humor is HUGE globally

Account 3: @judgymac.clips — reaction/UGC reposts
  Repost user reactions, screenshots, funny roasts
```

**Reddit (English)**
```
r/macapps (145K) — "I made an app that judges your Mac habits"
r/mac (1.2M) — product launch
r/IndieHackers — build-in-public story
r/ProgrammerHumor (3.5M) — meme about "my IDE judging my code"
r/productivity — "the anti-productivity app"
```

**Product Hunt (English)**
```
Tagline: "Your Mac has opinions about your life choices"
Hunter: find a top hunter with 1000+ followers
Demo: GIF/video of notification appearing mid-work
```

**Twitter/X (English)**
```
Build-in-public thread: "I built an app that roasts you"
Engage indie dev community (#buildinpublic #indiehackers)
Reply to SlapMac tweets: "What if your Mac didn't just scream — it JUDGED you?"
```

**Press/Media (English)**
```
Target: 9to5Mac, MacRumors, The Verge, Lifehacker
Angle: "The anti-productivity app that went viral"
Timing: Pitch 1 week before Product Hunt launch
```

### Revenue Projection — International Model

| Source | Monthly Downloads | Conv. | Rev/User | Monthly Net |
|--------|-------------------|-------|----------|-------------|
| US/CA | 8,000 | 5% | $4.00 | $1,360 |
| UK/AU | 3,000 | 4% | $3.50 | $357 |
| EU | 4,000 | 3% | $3.00 | $306 |
| Japan/Korea | 2,000 | 4% | $3.00 | $204 |
| ROW | 3,000 | 2% | $2.00 | $102 |
| **Total** | **20,000** | **~4%** | **~$3.50** | **$2,329** |

> Scale nay can tang len 3-4x de dat $100K/nam.
> Viral moment (TikTok hit hoac press coverage) co the push len 100K+ downloads/thang.

---

## 3. Features

### Core Features (MVP — Phase 1)

| Feature | Mo ta |
|---------|-------|
| **7 Behavior Triggers** | Lid open, lid open som/khuya, lid re-open, typing aggressive, type-delete, thermal, idle |
| **Menu Bar Face Icon** | Animated face thay doi mood (neutral, judging, horrified, sleeping, raging) |
| **Roast Notifications** | macOS notifications voi text roast co personality |
| **Roast Popover Panel** | Click menu bar → beautiful dropdown voi current judgment + stats |
| **1 Free Personality** | "The Critic" — sarcastic, witty, general audience |
| **Daily Stats** | So lan trigger, thoi gian active, roast count |
| **Anti-Repetition System** | Cooldown tracker, weight decay, daily cap (20 roasts) |
| **Settings** | Intensity slider, per-trigger toggle, language, launch at login |

### Premium Features (Phase 2)

| Feature | Mo ta | Price |
|---------|-------|-------|
| **Personality Packs** | Moi pack = 50+ templates, unique voice | $1.99/pack |
| **Daily Roast Summary** | Shareable card tong hop ngay — designed for Stories/TikTok | Pro |
| **Roast History** | Xem lai 100 roasts gan nhat | Pro |
| **Custom Triggers** | Bat/tat tung trigger, custom cooldown | Pro |
| **Sound Effects** | Optional sound khi roast (disapproving "hmm", gasp) | Pro |

### Personality Packs (IAP)

| Pack | Language | Vibe | Priority |
|------|----------|------|----------|
| **The Critic** (FREE) | EN | Witty, sarcastic observer | MVP |
| **Vietnamese Mom** | VI | "Con nha nguoi ta", guilt trips | MVP |
| **Toxic Boss** | EN | Corporate passive-aggressive | Phase 2 |
| **Drill Sergeant** | EN | Military tough love | Phase 2 |
| **Shakespeare** | EN | Elizabethan insults | Phase 2 |
| **Therapist Who Gave Up** | EN | "I'm not mad, just disappointed" | Phase 2 |
| **Gordon Ramsay Mode** | EN | Kitchen nightmare energy | Phase 2 |
| **Seasonal Packs** | Mixed | Holiday, Tax Season, Back to School | Quarterly |

### Post-MVP Features (Phase 3+)

| Feature | Phase | Mo ta |
|---------|-------|-------|
| AI Roasts (Foundation Models) | 3.0 | On-device AI cho macOS 26+ |
| iOS Companion App | 3.0 | iPhone version, iCloud sync |
| Widget (Notification Center) | 3.1 | Glanceable daily stats |
| Streak System | 3.1 | "30 ngay bi judge lien tiep" |
| Community Packs | 3.2 | User-submitted roast packs |
| Multiplayer Roast | 3.3 | Compare stats voi ban be |

---

## 4. Monetization Strategy

### Pricing Model: Free Trial + $4.99 One-Time Purchase

```
FREE (trial)
├── 3 roasts/ngay
├── 1 personality (The Critic)
├── 3 triggers (lid open, idle, thermal)
├── Basic stats
└── Menu bar face icon

FULL VERSION — $4.99 one-time (non-consumable IAP)
├── ALL 6 personalities
├── ALL 7 triggers
├── Unlimited roasts/ngay (cap 50)
├── Daily summary card (shareable)
├── Full roast history
├── Future updates included
└── No subscription. Buy once, own forever.
```

> Tai sao $4.99 one-time thay vi subscription?
> - Mac users prefer one-time purchase (SlapMac ban $7, CARROT Weather bat dau nhu vay)
> - Khong ai thich subscription cho 1 novelty app
> - $4.99 la impulse buy — re hon 1 ly ca phe
> - Don gian hoa code, marketing, va user trust
> - Apple Small Business Program = 15% commission → net $4.24/sale

### Revenue Math

| Scenario | Monthly Downloads | Conversion | Net/Sale | Monthly Net |
|----------|-------------------|------------|----------|-------------|
| Conservative | 5,000 | 5% | $4.24 | $1,060 |
| Realistic | 15,000 | 8% | $4.24 | $5,088 |
| Optimistic | 50,000 | 10% | $4.24 | $21,200 |
| Viral | 200,000 | 10% | $4.24 | $84,800 |

> $100K target = ~24,000 paid users = ~$8,500/thang
> One-time purchase co conversion rate cao hon subscription (8-10% vs 2-3%)

### Distribution Strategy

**Phase 1:** App Store only (StoreKit 2, Small Business Program 15%)
**Phase 2:** Add direct sales via Lemon Squeezy ($4.99, 5% commission) neu can

### Key Rules

1. Show paywall **sau khi user nhan 3 roasts** (free limit reached)
2. Soft paywall: 1 button, 1 price, list features, khong aggressive
3. Upsell banner nhe nhang trong popover (khong block UI)
4. "Restore Purchase" luon visible

---

## 5. System Architecture

### Project Structure

```
JudgyMac/
├── App/
│   ├── JudgyMacApp.swift              # Entry point, MenuBarExtra
│   ├── AppDelegate.swift               # NSApplicationDelegate
│   ├── AppState.swift                  # @Observable global state
│   └── OnboardingView.swift            # First-launch permissions + tour
│
├── MenuBar/
│   ├── MenuBarView.swift               # Popover dropdown UI
│   ├── MenuBarIcon.swift               # Animated face renderer
│   ├── MoodEngine.swift                # Events → mood mapping
│   └── PopoverPanel.swift              # Custom NSPopover setup
│
├── Detection/
│   ├── DetectionCoordinator.swift      # Orchestrates all detectors
│   ├── Protocols/
│   │   └── BehaviorDetector.swift      # Protocol chung
│   ├── LidDetector.swift               # IOKit power notifications
│   ├── TypingDetector.swift            # NSEvent global monitor
│   ├── ThermalDetector.swift           # ProcessInfo.thermalState
│   ├── IdleDetector.swift              # CGEventSource idle time
│   └── TimeOfDayDetector.swift         # Clock-based triggers
│
├── Roast/
│   ├── RoastEngine.swift               # Select + format roast
│   ├── RoastTemplate.swift             # Template model
│   ├── RoastCooldownTracker.swift      # Anti-repetition
│   ├── PersonalityPack.swift           # Personality model
│   └── RoastPresenter.swift            # Deliver via notification
│
├── Store/
│   ├── StoreManager.swift              # StoreKit 2 — products, purchases
│   ├── EntitlementManager.swift        # What user has unlocked
│   ├── ProductIdentifiers.swift        # Product ID constants
│   └── PaywallView.swift              # IAP purchase UI
│
├── Models/
│   ├── BehaviorEvent.swift             # Event enum + metadata
│   ├── Mood.swift                      # Mood enum
│   ├── UserStats.swift                 # Daily counters
│   └── RoastEntry.swift                # Roast log entry
│
├── Persistence/
│   ├── StatsStore.swift                # UserDefaults daily stats
│   ├── RoastHistory.swift              # Last 100 roasts (actor-based)
│   └── SettingsStore.swift             # @AppStorage preferences
│
├── Summary/
│   ├── DailySummaryGenerator.swift     # Compile daily summary
│   ├── SummaryCardView.swift           # Shareable card view
│   └── SummaryShareHelper.swift        # Export PNG + share sheet
│
├── Settings/
│   ├── SettingsView.swift              # Settings window
│   ├── PersonalityPickerView.swift     # Personality selector + store
│   ├── TriggerToggleView.swift         # Enable/disable triggers
│   └── IntensitySliderView.swift       # Roast intensity
│
├── Design/
│   ├── Theme.swift                     # Colors, fonts, spacing
│   ├── GlassCard.swift                 # Reusable glass-morphism card
│   ├── AnimatedFace.swift              # Face component with expressions
│   └── RoastBubble.swift              # Chat-bubble style roast text
│
├── Resources/
│   ├── Roasts/
│   │   ├── en/
│   │   │   ├── the-critic.json         # FREE default
│   │   │   ├── toxic-boss.json
│   │   │   ├── drill-sergeant.json
│   │   │   ├── shakespeare.json
│   │   │   ├── therapist.json
│   │   │   └── gordon-ramsay.json
│   │   └── vi/
│   │       ├── the-critic.json
│   │       └── vietnamese-mom.json
│   ├── Sounds/
│   │   ├── hmm.mp3
│   │   ├── gasp.mp3
│   │   └── tsk-tsk.mp3
│   └── Faces/
│       ├── neutral.png
│       ├── judging.png
│       ├── horrified.png
│       ├── sleeping.png
│       └── raging.png
│
├── i18n/
│   └── Localizable.xcstrings           # UI strings (Apple String Catalog)
│
└── Utilities/
    ├── CGEventTapHelper.swift           # Event tap wrapper
    └── Constants.swift                  # App-wide constants
```

### Data Flow

```
Detector → BehaviorEvent → DetectionCoordinator
                                ↓
                           AppState (@Observable)
                          ↙    ↓         ↘
                   MoodEngine  RoastEngine  StatsStore
                      ↓           ↓             ↓
                MenuBarIcon  RoastPresenter  UserStats
                (face mood)  (notification)  (persist)
                                ↓
                          RoastHistory (log)
                                ↓
                      DailySummaryGenerator
                                ↓
                        SummaryCardView (share)
```

### Detection — Technical Details

| Detector | API | Sandbox? | Permission? |
|----------|-----|----------|-------------|
| LidDetector | `IORegisterForSystemPower()` — kIOMessageSystemHasPoweredOn/Sleep | OK | Khong |
| TypingDetector | `NSEvent.addGlobalMonitorForEvents(.keyDown)` — chi do timing | OK | Accessibility |
| ThermalDetector | `ProcessInfo.processInfo.thermalState` | OK | Khong |
| IdleDetector | `CGEventSource.secondsSinceLastEventType(.combinedSessionState)` | OK | Khong |
| TimeOfDayDetector | `Date()` + Calendar | OK | Khong |

> 5/7 triggers hoat dong KHONG can Accessibility. Typing la optional.

### StoreKit 2 Architecture

```swift
// Product IDs
enum ProductID {
    // Non-consumable packs
    static let vietnameseMom = "com.judgymac.pack.vietnamese_mom"
    static let toxicBoss = "com.judgymac.pack.toxic_boss"
    static let drillSergeant = "com.judgymac.pack.drill_sergeant"
    static let shakespeare = "com.judgymac.pack.shakespeare"
    static let therapist = "com.judgymac.pack.therapist"
    static let gordonRamsay = "com.judgymac.pack.gordon_ramsay"

    // Auto-renewable subscription
    static let proMonthly = "com.judgymac.pro.monthly"
    static let proYearly = "com.judgymac.pro.yearly"
}
```

### Roast JSON Format

```json
{
  "personality": "vietnamese-mom",
  "language": "vi",
  "productId": "com.judgymac.pack.vietnamese_mom",
  "templates": {
    "lid_open": [
      {
        "id": "lid_vi_mom_001",
        "text": "Lai mo may a? Hom nay {count} lan roi. Con nha nguoi ta thi di ngu som.",
        "variables": ["count"],
        "intensity": 2,
        "weight": 1.0
      }
    ],
    "late_night": [
      {
        "id": "late_vi_mom_001",
        "text": "{hour} gio dem roi ma con thuc. Mai day duoc khong day?",
        "variables": ["hour"],
        "intensity": 1,
        "weight": 1.0
      }
    ]
  }
}
```

### Anti-Repetition System

```
1. Cung template khong lap trong 24h
2. Cung trigger type cooldown toi thieu 5 phut
3. Free tier: 5 roasts/ngay | Pro: 20 roasts/ngay (configurable)
4. Weight giam sau khi dung, reset hang ngay
5. Random selection weighted by: (base_weight × decay_factor)
```

---

## 6. UI/UX Design — "Sexy Dark Aesthetic"

### Design Philosophy

```
Dark & Moody → Premium feel, matches "judgy" personality
Glass Morphism → Native macOS vibrancy, depth
Personality First → Roast text is the HERO element
Micro-interactions → Every state change is animated
```

### Color Palette

```
┌─────────────────────────────────────────────┐
│  BACKGROUNDS                                │
│  ██ #0D0D0F  Near-black (primary)           │
│  ██ #1A1A2E  Dark navy (secondary)          │
│  ██ #16213E  Deep blue (cards)              │
│                                             │
│  ACCENTS                                    │
│  ██ #E040FB  Hot magenta (CTA, highlights)  │
│  ██ #7C4DFF  Electric purple (secondary)    │
│  ██ #FF5252  Rage red (angry states)        │
│  ██ #00E5FF  Cyan (stats, data)             │
│  ██ #69F0AE  Mint green (positive states)   │
│                                             │
│  TEXT                                       │
│  ██ #F5F5F7  Primary text                   │
│  ██ #8E8E93  Secondary text                 │
│  ██ #48484A  Tertiary/disabled              │
│                                             │
│  GLASS                                      │
│  ░░ rgba(255,255,255,0.06)  Card fill       │
│  ── rgba(255,255,255,0.08)  Card border     │
│  ▓▓ .ultraThinMaterial      Popover bg      │
└─────────────────────────────────────────────┘
```

### Typography

```
Headings:     SF Pro Rounded Bold (playful, friendly)
Roast Text:   SF Pro Rounded Semibold, 18-22pt (the HERO)
Body:         SF Pro Text Regular, 13-14pt
Stats:        SF Mono Medium, 12pt (data clarity)
Labels:       SF Pro Text Medium, 11pt, uppercase tracking
```

### Menu Bar Popover Layout

```
┌──────────────────────────────────────┐  340px wide
│                                      │
│    ╭─────╮                           │
│    │ 🤨  │  JudgyMac        ⚙️      │  ← Animated face + settings
│    ╰─────╯                           │
│                                      │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  │  "You opened this lid 7 times │  │  ← HERO: Current roast
│  │   today. What are you looking │  │     Large text, glass card
│  │   for? Meaning? It's not in   │  │     Gradient border glow
│  │   there."                     │  │
│  │                                │  │
│  │              — The Critic  🤨  │  │  ← Personality attribution
│  └────────────────────────────────┘  │
│                                      │
│  ┌──────────┐  ┌──────────┐         │
│  │  🚪 12   │  │  ⌨️ 847  │         │  ← Stats cards (glass tiles)
│  │ Lid Opens │  │Keystrokes│         │     Animated counters
│  └──────────┘  └──────────┘         │
│  ┌──────────┐  ┌──────────┐         │
│  │  🔥 3    │  │  😴 23m  │         │
│  │  Roasts  │  │Max Idle  │         │
│  └──────────┘  └──────────┘         │
│                                      │
│  Today's Vibe: Serial Procrastinator │  ← Daily vibe label
│  ━━━━━━━━━━━━━━━━░░░░░░░░░░░░░░░░  │  ← Judgment bar (animated)
│                                      │
│  ┌────────────────────────────────┐  │
│  │ 👑 Unlock Vietnamese Mom  →   │  │  ← Soft upsell (glass card)
│  │    Preview: "May gio roi..."  │  │     Shows sample roast
│  └────────────────────────────────┘  │
│                                      │
│  📊 History    📤 Share    ✨ Pro    │  ← Footer actions
│                                      │
└──────────────────────────────────────┘
```

### Menu Bar Face Icon — 6 Moods

```
Neutral:    (•‿•)    → Default idle state, occasional blink
Judging:    (•_•)    → One eyebrow raised (signature look)
Horrified:  (◉_◉)    → Wide eyes, user did something wild
Sleeping:   (—‿—)zzz → Closed eyes, user idle too long
Raging:     (╬ಠ益ಠ)  → Red tint, angry (thermal/aggressive typing)
Impressed:  (⊙_⊙)    → Rare — user actually did something good
```

Implementation: 18x18 @2x pixel art PNG frames, swap via `statusItem.button?.image`.
Smooth transitions with `CATransition` (0.3s crossfade).

### Key UI Components

**GlassCard** — Reusable glass-morphism container
```swift
struct GlassCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
```

**RoastBubble** — Chat-bubble style roast display
```swift
struct RoastBubble: View {
    let text: String
    let personality: String
    let mood: Mood

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .lineSpacing(4)

            HStack {
                Text("— \(personality)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(mood.emoji)
                    .font(.title3)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.15), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
```

### Notification Style

```
┌────────────────────────────────────────────┐
│ 🤨 JudgyMac                    just now   │
│                                            │
│ You opened this lid 7 times today.         │
│ What are you looking for? Meaning?         │
│ It's not in there.                         │
│                                            │
│ [Shut up]              [More like this]    │
└────────────────────────────────────────────┘
```

Actionable notifications: "Shut up" = snooze 1h, "More like this" = engagement signal.

### Daily Summary Card (Shareable)

```
┌────────────────────────────────────────┐
│                                        │
│           🤨 JudgyMac                  │
│        March 30, 2026                  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │                                  │  │
│  │   Today you:                     │  │
│  │   • Opened your laptop 12 times  │  │
│  │   • Typed 4,200 angry keystrokes │  │
│  │   • Were idle for 2.3 hours      │  │
│  │   • Got roasted 15 times         │  │
│  │                                  │  │
│  │   Verdict: "Impressively useless"│  │
│  │                                  │  │
│  └──────────────────────────────────┘  │
│                                        │
│         judgymac.com                    │
│                                        │
└────────────────────────────────────────┘

Background: dark gradient with subtle noise texture
Export: PNG 1080x1350 (Instagram Stories) + 1080x1080 (feed)
```

### Onboarding Flow (4 screens)

```
Screen 1: "Meet Your New Judge"
  → Animated face waving, brief intro

Screen 2: "What I'll Watch"
  → Toggle triggers (pre-select safe defaults)
  → Show which need Accessibility permission

Screen 3: "Pick Your Poison"
  → Preview personalities (play sample roasts)
  → Free: The Critic | Paid: others (soft preview)

Screen 4: "Ready to Be Judged?"
  → Request notification permission
  → "Let the judging begin" CTA
```

---

## 7. Landing Page — judgymac.com

### Tech Stack
**Framer** (Phase 1 — fast launch) → **Astro + Tailwind** (Phase 2 — more control)

### Page Structure

```
SECTION 1: HERO
┌─────────────────────────────────────────────────────────┐
│                                                         │
│              [dark gradient bg + subtle stars]           │
│                                                         │
│                    ╭─────╮                              │
│                    │ 🤨  │  ← Large animated face       │
│                    ╰─────╯                              │
│                                                         │
│          Your Mac has opinions                          │
│        about your life choices.                         │
│                                                         │
│     It watches. It judges. It sends notifications.      │
│                                                         │
│          [ Download Free ]  ← Glowing CTA button        │
│           macOS 14+ • Apple Silicon                     │
│                                                         │
│     ┌──────────────────────────────────┐                │
│     │  Screenshot of popover panel     │  ← Floating    │
│     │  with glass effect + roast text  │    with shadow  │
│     └──────────────────────────────────┘                │
│                                                         │
└─────────────────────────────────────────────────────────┘

SECTION 2: ROAST SHOWCASE (scroll-triggered)
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  "What your Mac ACTUALLY thinks"                        │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ 🤨           │  │ 😤           │  │ 😴           │  │
│  │ "Lid opened  │  │ "120 WPM?   │  │ "47 minutes  │  │
│  │  12 times.   │  │  Who hurt    │  │  idle. Did   │  │
│  │  Looking for │  │  you?"       │  │  you die?"   │  │
│  │  meaning?"   │  │              │  │              │  │
│  │  — Critic    │  │ — Viet Mom   │  │ — Therapist  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                         │
│  Cards fade in one-by-one on scroll                     │
│                                                         │
└─────────────────────────────────────────────────────────┘

SECTION 3: FEATURES (icon grid)
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  7 Ways Your Mac Judges You                             │
│                                                         │
│  🚪 Lid Open       ⌨️ Angry Typing    🔥 Overheating   │
│  😴 Too Idle       🌙 Late Night      🔄 Lid Re-open   │
│  ✍️ Type & Delete                                       │
│                                                         │
│  Each with icon + 1-line description + sample roast     │
│                                                         │
└─────────────────────────────────────────────────────────┘

SECTION 4: PERSONALITIES
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Choose Your Judge                                      │
│                                                         │
│  Carousel of personality cards:                         │
│  [The Critic] [Vietnamese Mom] [Toxic Boss] [...]       │
│                                                         │
│  Each card: face + name + sample roast + price tag      │
│  Click to hear/read more samples                        │
│                                                         │
└─────────────────────────────────────────────────────────┘

SECTION 5: DAILY SUMMARY PREVIEW
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Share Your Judgment                                    │
│                                                         │
│  [Mockup of daily summary card in iPhone/Instagram]     │
│  "Your friends need to see this"                        │
│                                                         │
└─────────────────────────────────────────────────────────┘

SECTION 6: SOCIAL PROOF (post-launch)
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  People Roasted by JudgyMac                             │
│                                                         │
│  [Tweet-style cards with user reactions]                │
│  [TikTok embed of someone getting roasted]              │
│                                                         │
└─────────────────────────────────────────────────────────┘

SECTION 7: DOWNLOAD CTA
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           Ready to be judged?                           │
│                                                         │
│           [ Download Free ]                             │
│                                                         │
│      Free forever • Pro from $1.99/mo                   │
│      macOS 14+ Sonoma • Apple Silicon                   │
│                                                         │
└─────────────────────────────────────────────────────────┘

FOOTER
┌─────────────────────────────────────────────────────────┐
│  JudgyMac © 2026          Twitter  GitHub  Support      │
│  Privacy Policy  Terms                                  │
└─────────────────────────────────────────────────────────┘
```

### Landing Page Design Specs

```
Background: Linear gradient #0D0D0F → #1A1A2E
Font: Inter (headings) + Inter (body) — web equivalent of SF Pro Rounded
Hero animation: Lottie/CSS animation of face changing expressions
CTA button: Hot magenta (#E040FB) with glow shadow + hover scale
Cards: Glass-morphism (backdrop-filter: blur(20px), bg rgba(255,255,255,0.05))
Scroll animations: Intersection Observer + CSS transforms (fade-up)
Mobile responsive: Stack horizontally, increase touch targets
```

---

## 8. Marketing Plan — International First

> Moi noi dung marketing = ENGLISH. Vietnamese Mom la viral hook, khong phai primary language.

### Pre-Launch (2 weeks truoc launch)

| Action | Platform | Language | Goal |
|--------|----------|----------|------|
| Teaser videos (roast notifications) | TikTok @judgymac | EN | Build US/global audience |
| "Vietnamese Mom vs MacBook" series | TikTok @judgymac.vn | VI/EN subs | Viral wildcard |
| Landing page live | judgymac.com | EN | Email waitlist |
| Beta testers (50 people) | Twitter, Reddit | EN | Feedback + testimonials |
| Pitch to 9to5Mac, MacRumors | Email | EN | Press embargo for launch day |
| Build-in-public thread | Twitter/X | EN | Indie dev community engagement |

### Launch Week

| Day | Action | Target |
|-----|--------|--------|
| D-1 | Product Hunt "Coming Soon" + email blast | Global |
| D0 | Product Hunt launch (EN) + TikTok blitz (3 EN videos) | US/EU |
| D0 | Reddit: r/macapps, r/mac, r/IndieHackers (EN) | US/EU |
| D0 | Hacker News "Show HN" (EN) | US/EU tech |
| D1 | Twitter/X thread: "I built an app that judges you" | EN indie dev community |
| D1 | Vietnamese Mom TikTok: "My Mac became my Asian mom" | Asian diaspora (US/AU/UK) |
| D2 | TikTok: "My MacBook called me out at 3am" POV | US Gen Z |
| D3-7 | Respond to EVERY comment in EN, repost user content | Global |

### Ongoing (TikTok-First Strategy — BePresent Playbook)

```
Content cadence: 5-7 TikTok/Reels per week across 3 accounts
Budget: $0 organic + $300/month micro-influencer (US-based creators)

Account 1: @judgymac (EN — primary)
  Hook examples:
  - "POV: your Mac starts judging your life choices"
  - "My Mac said this to me at 3am"
  - "Things my MacBook judges me for"
  - "I gave my Mac a personality and now it won't shut up"
  Format: screen recording of notification appearing, reaction face

Account 2: @judgymac.vn (VI/EN — viral niche)
  Hook examples:
  - "Vietnamese Mom mode is BRUTAL"
  - "When your MacBook turns into an Asian parent"
  - "My Mac said 'con nha nguoi ta' to me"
  Format: same but with Vietnamese text, EN subtitles
  Target: Asian diaspora in US/AU/UK (English-speaking, culturally Vietnamese)

Account 3: @judgymac.clips (EN — UGC reposts)
  Repost user reactions, screenshots, funny roasts
  "Best roasts this week" compilations
```

### Micro-Influencer Strategy (Blake Anderson Playbook)

```
Budget: $300/month (6 creators × $50/video)
Target: US-based Mac/tech TikTok creators with 10K-100K followers
Brief: "Screen record JudgyMac roasting you, react genuinely"
Format: 15-30 sec, authentic reaction, no script
Expected: 50K-200K views per video at $50 = best ROI possible
```

### Viral Loops Built Into Product

1. **Daily summary card** → designed for Instagram Stories (1080x1350) with `judgymac.com` watermark
2. **Roast notifications** → screenshot-friendly, include "— JudgyMac" attribution
3. **"Share this roast"** button → copy text + judgymac.com link (deep link when iOS launches)
4. **"Vietnamese Mom judged me"** → cultural meme potential in Asian diaspora communities
5. **Personality pack previews** → "Unlock to see what Gordon Ramsay thinks of you"
6. **Weekly "Most Judged" leaderboard** (anonymous) → "You were in the top 5% most judged users this week"

### Community Building (English-first)

| Platform | Strategy | Cadence |
|----------|----------|---------|
| **Discord** | JudgyMac community — share roasts, suggest new packs, vote on features | Launch day |
| **Twitter/X** | #JudgedByMyMac hashtag, build-in-public updates | Daily |
| **Reddit** | r/JudgyMac subreddit (when >1K users) | Weekly |
| **Newsletter** | "Weekly Roast Digest" — best roasts, new packs, behind-the-scenes | Weekly |

---

## 9. Development Phases & Timeline

### Phase 1: Foundation (Day 1-3)

| Task | Files |
|------|-------|
| Xcode project setup, MenuBarExtra skeleton | JudgyMacApp.swift, AppDelegate.swift |
| AppState (@Observable) | AppState.swift |
| Theme system (colors, fonts, glass components) | Theme.swift, GlassCard.swift |
| Menu bar icon (static, 6 mood PNGs) | MenuBarIcon.swift, Faces/ |
| Basic popover panel (empty shell) | PopoverPanel.swift, MenuBarView.swift |

### Phase 2: Detection (Day 3-6)

| Task | Files |
|------|-------|
| BehaviorDetector protocol | BehaviorDetector.swift |
| LidDetector (IOKit) | LidDetector.swift |
| IdleDetector (CGEventSource) | IdleDetector.swift |
| ThermalDetector (ProcessInfo) | ThermalDetector.swift |
| TimeOfDayDetector | TimeOfDayDetector.swift |
| TypingDetector (optional, Accessibility) | TypingDetector.swift |
| DetectionCoordinator | DetectionCoordinator.swift |

### Phase 3: Roast Engine (Day 6-9)

| Task | Files |
|------|-------|
| RoastTemplate model + JSON loading | RoastTemplate.swift |
| PersonalityPack model | PersonalityPack.swift |
| RoastEngine (selection, variables, formatting) | RoastEngine.swift |
| RoastCooldownTracker | RoastCooldownTracker.swift |
| RoastPresenter (UNUserNotification) | RoastPresenter.swift |
| Write "The Critic" EN templates (80+ roasts) | en/the-critic.json |
| Write "Vietnamese Mom" VI templates (50+ roasts) | vi/vietnamese-mom.json |

### Phase 4: UI Polish (Day 9-12)

| Task | Files |
|------|-------|
| Popover UI complete (roast bubble, stats, vibe bar) | MenuBarView.swift, RoastBubble.swift |
| MoodEngine (events → face mood transitions) | MoodEngine.swift |
| Animated face transitions (crossfade) | MenuBarIcon.swift |
| Stats persistence + display | StatsStore.swift, UserStats.swift |
| Roast history view | RoastHistory.swift |
| Settings UI | SettingsView.swift + sub-views |
| Onboarding flow (4 screens) | OnboardingView.swift |

### Phase 5: Monetization (Day 12-15)

| Task | Files |
|------|-------|
| StoreKit 2 setup (products, purchase flow) | StoreManager.swift |
| EntitlementManager (check unlocks) | EntitlementManager.swift |
| PaywallView (soft paywall, pack previews) | PaywallView.swift |
| PersonalityPickerView (integrated with store) | PersonalityPickerView.swift |
| Lock/unlock logic in RoastEngine | RoastEngine.swift |
| StoreKit testing configuration | JudgyMac.storekit |

### Phase 6: Share & Summary (Day 15-17)

| Task | Files |
|------|-------|
| DailySummaryGenerator | DailySummaryGenerator.swift |
| SummaryCardView (shareable PNG) | SummaryCardView.swift |
| Share functionality | SummaryShareHelper.swift |
| Actionable notifications (Shut up / More) | RoastPresenter.swift |

### Phase 7: Landing Page (Day 15-17, parallel)

| Task | Tool |
|------|------|
| Design in Framer | Framer |
| Hero section + face animation | Lottie / CSS |
| Feature sections + scroll animations | Framer built-in |
| Download CTA + pricing | Framer |
| Custom domain judgymac.com | Framer + DNS |

### Phase 8: Polish & Ship (Day 17-21)

| Task |
|------|
| Write 3-5 more personality pack JSON files |
| App icon design (the judgy face) |
| Accessibility audit (VoiceOver, reduce motion) |
| Performance profiling (battery, CPU) |
| TestFlight beta (50 testers) |
| App Store screenshots + description |
| App Store submission |
| Product Hunt "Coming Soon" page |

---

## 10. Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| App Store reject (Accessibility permission) | Cao | Typing = optional, 5/7 triggers khong can permission |
| SlapMac mo rong overlap triggers | Trung binh | Compete on personality/text/context, NOT triggers. SlapMac = sounds, JudgyMac = personality |
| SlapMac comparison "copycat" | Thap | Completely different mechanics (behavioral vs physical), different output (text vs sound) |
| Roast lap sau 2 tuan | Trung binh | 80+ templates/personality, cooldown, weight decay |
| User thay annoying | Trung binh | Intensity slider, per-trigger toggle, daily cap, snooze |
| Humor khong dich duoc | Trung binh | Viet rieng theo ngon ngu, KHONG dich. Hire native humor writers |
| Low conversion rate | Cao | Soft paywall, preview roasts, 7-day trial, $1.99 entry |
| TikTok algorithm thay doi | Trung binh | Multi-platform (TikTok + Twitter + Reddit + Product Hunt) |
| EN humor khong du hay (non-native writer) | Cao | Hire EN-native comedy writer for templates, or use AI + human review |
| VN market khong du de kiem tien | Da giai quyet | English-first strategy, VN chi la viral hook |
| Mac-only gioi han TAM | Cao | iOS companion app trong 3 thang, expand TAM 10x |

---

## 11. Success Metrics

### Month 1 Targets

| Metric | Target |
|--------|--------|
| Downloads | 5,000+ |
| Product Hunt upvotes | 300+ |
| DAU/MAU ratio | >30% |
| IAP conversion | >3% |
| App Store rating | >4.5 stars |
| TikTok views (total) | 500K+ |

### $100K Milestone Path

```
Month 1-2:   Launch + Product Hunt spike       → $2-5K
Month 3-4:   TikTok content engine running      → $3-8K/mo
Month 5-6:   iOS version launch                 → $8-15K/mo
Month 7-12:  Compound growth + seasonal packs   → $10-20K/mo
─────────────────────────────────────────────────────────
Year 1 Total:                                   → $60-150K
```

---

## 12. Tech Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Language | Swift 6 | Native, best macOS integration |
| UI | SwiftUI | Modern, declarative, @Observable |
| Menu bar | MenuBarExtra | Native macOS API |
| Popover | NSPopover + SwiftUI hosting | Best control over size/behavior |
| Persistence | UserDefaults + actor-based file store | Simple, no CoreData needed |
| IAP | StoreKit 2 | Async/await, no receipt validation |
| Distribution | App Store (primary) + Lemon Squeezy (later) | Max reach + backup channel |
| Landing page | Framer → Astro | Fast launch → full control |
| Analytics | TelemetryDeck (privacy-first) | GDPR compliant, Mac-native |
| CI/CD | Xcode Cloud | Free for small teams, built-in |

---

## 13. Post-MVP Roadmap

| Version | Feature | Timeline |
|---------|---------|----------|
| 1.1 | 3 more personality packs | +2 weeks |
| 1.2 | iOS companion app | +1 month |
| 1.3 | Widget (Notification Center) | +1.5 months |
| 2.0 | AI Roasts (Apple Foundation Models, macOS 26+) | +3 months |
| 2.1 | Streak system + achievements | +3.5 months |
| 2.2 | Community packs marketplace | +4 months |
| 2.3 | iCloud sync (Mac ↔ iPhone) | +4.5 months |
| 2.4 | Multiplayer — compare stats with friends | +5 months |
