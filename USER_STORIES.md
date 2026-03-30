# JudgyMac — User Stories & Progress Tracker

> Last updated: 2026-03-30
> Status: Phase 1 — Foundation

---

## Epic 1: Foundation & App Shell (Day 1-3)

### US-1.1: Menu Bar Presence
**As a** Mac user,
**I want** to see a small face icon in my menu bar,
**So that** I know JudgyMac is running.

**Acceptance Criteria:**
- [ ] App launches as menu bar app (no Dock icon)
- [ ] Face icon visible in menu bar (18x18 @2x)
- [ ] App starts with "neutral" face by default
- [ ] Right-click shows "Quit JudgyMac" option

**Files:** `JudgyMacApp.swift`, `AppDelegate.swift`, `MenuBarIcon.swift`

---

### US-1.2: Popover Panel
**As a** user,
**I want** to click the menu bar icon and see a beautiful dropdown panel,
**So that** I can see my current status and latest roast.

**Acceptance Criteria:**
- [ ] Click icon → popover appears (340px wide, dark glass aesthetic)
- [ ] Shows app name + face icon at top
- [ ] Shows placeholder text for current roast (RoastBubble)
- [ ] Shows 4 stats cards (placeholders: Lid Opens, Keystrokes, Roasts, Max Idle)
- [ ] Shows "Today's Vibe" label + judgment bar
- [ ] Footer with History, Share, Pro buttons
- [ ] Click outside → popover dismisses
- [ ] Popover uses glass-morphism (`.ultraThinMaterial`)

**Files:** `PopoverPanel.swift`, `MenuBarView.swift`, `GlassCard.swift`, `RoastBubble.swift`, `Theme.swift`

---

### US-1.3: Theme System
**As a** developer,
**I want** a centralized theme with colors, fonts, and reusable components,
**So that** the UI is consistent and "sexy" across the app.

**Acceptance Criteria:**
- [ ] Theme.swift defines all colors (near-black, magenta, purple, cyan, etc.)
- [ ] Theme.swift defines all font styles (SF Pro Rounded for headings, SF Mono for stats)
- [ ] GlassCard component: glass background + border + shadow
- [ ] RoastBubble component: gradient border glow + personality attribution
- [ ] AnimatedFace component: displays mood-based face image

**Files:** `Theme.swift`, `GlassCard.swift`, `RoastBubble.swift`, `AnimatedFace.swift`

---

### US-1.4: App State
**As a** developer,
**I want** a central observable state object,
**So that** all UI components react to changes automatically.

**Acceptance Criteria:**
- [ ] AppState is `@Observable` class
- [ ] Tracks: currentMood, currentRoast, todayStats, isOnboarded, selectedPersonality
- [ ] Accessible throughout the app via SwiftUI environment

**Files:** `AppState.swift`

---

## Epic 2: Behavior Detection (Day 3-6)

### US-2.1: Lid Open Detection
**As a** user,
**I want** JudgyMac to notice when I open my laptop,
**So that** it can judge me for opening it too many times.

**Acceptance Criteria:**
- [ ] Detect system wake from sleep (IOKit power notifications)
- [ ] Count lid opens per day
- [ ] Distinguish: normal open, re-open within 30s, early morning (<6am), late night (>midnight)
- [ ] Emit `BehaviorEvent.lidOpen(count:, context:)` to AppState

**Files:** `LidDetector.swift`, `BehaviorEvent.swift`

---

### US-2.2: Idle Detection
**As a** user,
**I want** JudgyMac to notice when I've been idle too long,
**So that** it can roast me for doing nothing.

**Acceptance Criteria:**
- [ ] Poll `CGEventSource.secondsSinceLastEventType` every 60s
- [ ] Trigger at configurable threshold (default: 15 min)
- [ ] Track max idle duration today
- [ ] Emit `BehaviorEvent.idle(minutes:)`

**Files:** `IdleDetector.swift`

---

### US-2.3: Thermal Detection
**As a** user,
**I want** JudgyMac to notice when my Mac is overheating,
**So that** it can judge what I'm doing to make it hot.

**Acceptance Criteria:**
- [ ] Monitor `ProcessInfo.processInfo.thermalState`
- [ ] Trigger on `.serious` or `.critical`
- [ ] Emit `BehaviorEvent.thermal(state:)`
- [ ] No special permissions required

**Files:** `ThermalDetector.swift`

---

### US-2.4: Time of Day Detection
**As a** user,
**I want** JudgyMac to judge me for using my Mac at weird hours,
**So that** I feel appropriately guilty at 3am.

**Acceptance Criteria:**
- [ ] Check time on each lid open event
- [ ] Categories: late night (0:00-5:00), early morning (5:00-6:30), normal
- [ ] Emit `BehaviorEvent.lateNight(hour:)` or `.earlyMorning(hour:)`

**Files:** `TimeOfDayDetector.swift`

---

### US-2.5: Typing Detection (Optional — Requires Accessibility)
**As a** user who grants Accessibility permission,
**I want** JudgyMac to detect when I'm typing aggressively or deleting a lot,
**So that** it can comment on my emotional state.

**Acceptance Criteria:**
- [ ] Use `NSEvent.addGlobalMonitorForEvents(.keyDown)` — measure timing ONLY, never read content
- [ ] Detect aggressive typing: >100 WPM sustained for 30s
- [ ] Detect type-delete pattern: >40% backspace ratio in 60s window
- [ ] Gracefully degrade if Accessibility not granted (other triggers still work)
- [ ] Emit `BehaviorEvent.aggressiveTyping(wpm:)` or `.typeDelete(ratio:)`

**Files:** `TypingDetector.swift`, `CGEventTapHelper.swift`

---

### US-2.6: Detection Coordinator
**As a** developer,
**I want** a single coordinator that manages all detectors,
**So that** they can be started/stopped together and events flow to AppState.

**Acceptance Criteria:**
- [ ] Start/stop all active detectors
- [ ] Route BehaviorEvents to AppState
- [ ] Respect user's trigger toggle settings (some triggers may be disabled)
- [ ] Handle detector errors gracefully

**Files:** `DetectionCoordinator.swift`, `BehaviorDetector.swift` (protocol)

---

## Epic 3: Roast Engine (Day 6-9)

### US-3.1: Template Loading
**As a** developer,
**I want** to load roast templates from JSON files,
**So that** content is separate from code and easy to update.

**Acceptance Criteria:**
- [ ] Load JSON files from `Resources/Roasts/{lang}/{personality}.json`
- [ ] Parse into `RoastTemplate` models with id, text, variables, intensity, weight
- [ ] Support variable placeholders: `{count}`, `{hour}`, `{wpm}`, `{idle_minutes}`, etc.
- [ ] Handle missing/malformed JSON gracefully

**Files:** `RoastTemplate.swift`, `PersonalityPack.swift`

---

### US-3.2: Roast Selection
**As a** user,
**I want** to receive a relevant, non-repetitive roast for each trigger,
**So that** the experience stays fresh and funny.

**Acceptance Criteria:**
- [ ] Select roast based on: trigger type + active personality + intensity setting
- [ ] Weighted random selection (higher weight = more likely)
- [ ] Inject context variables ({count} = lid opens today, {hour} = current hour, etc.)
- [ ] Never repeat same template within 24h
- [ ] Only show roasts with intensity <= user's intensity setting

**Files:** `RoastEngine.swift`

---

### US-3.3: Anti-Repetition / Cooldown
**As a** user,
**I want** roasts to not repeat or spam me,
**So that** each roast feels unique.

**Acceptance Criteria:**
- [ ] Same template: no repeat within 24h
- [ ] Same trigger type: minimum 5 min cooldown
- [ ] Daily cap: 5 roasts (free) / 20 roasts (pro)
- [ ] Weight decay: used template's weight drops, resets daily

**Files:** `RoastCooldownTracker.swift`

---

### US-3.4: Notification Delivery
**As a** user,
**I want** roasts delivered as macOS notifications,
**So that** I see them even when not looking at the menu bar.

**Acceptance Criteria:**
- [ ] Request notification permission on first launch
- [ ] Show roast text + personality name in notification
- [ ] Actionable buttons: "Shut up" (snooze 1h) + "More like this" (engagement signal)
- [ ] Notification includes JudgyMac face icon
- [ ] Update popover panel with same roast text

**Files:** `RoastPresenter.swift`

---

### US-3.5: Roast Content — "The Critic" (English, FREE)
**As an** English-speaking user,
**I want** a default free personality called "The Critic",
**So that** I can enjoy JudgyMac without paying.

**Acceptance Criteria:**
- [ ] 80+ roast templates across all 7 trigger types
- [ ] Tone: witty, sarcastic, observational humor
- [ ] Mix of short zingers and longer commentary
- [ ] All templates use proper English, tested for humor quality
- [ ] Variables used naturally in context

**Files:** `Resources/Roasts/en/the-critic.json`

---

### US-3.6: Roast Content — "Vietnamese Mom" (Vietnamese, PAID)
**As a** Vietnamese-speaking user (or anyone curious),
**I want** a "Vietnamese Mom" personality pack,
**So that** I can experience culturally authentic roasting.

**Acceptance Criteria:**
- [ ] 50+ roast templates across all 7 trigger types
- [ ] Tone: guilt trips, comparisons to "con nha nguoi ta", passive-aggressive love
- [ ] Culturally authentic Vietnamese humor (NOT translated from English)
- [ ] Locked behind IAP ($1.99) with 3 free preview roasts visible

**Files:** `Resources/Roasts/vi/vietnamese-mom.json`

---

## Epic 4: Mood & Stats (Day 9-12)

### US-4.1: Mood Engine
**As a** user,
**I want** the menu bar face to change expression based on what's happening,
**So that** I can see JudgyMac's "mood" at a glance.

**Acceptance Criteria:**
- [ ] Map events to moods: idle→sleeping, thermal→raging, lid open→judging, etc.
- [ ] Smooth transition between moods (0.3s crossfade)
- [ ] Default to neutral with occasional blink animation
- [ ] Mood affects popover UI accent color

**Files:** `MoodEngine.swift`, `Mood.swift`, `MenuBarIcon.swift`

---

### US-4.2: Daily Stats Tracking
**As a** user,
**I want** to see my daily behavior stats in the popover,
**So that** I can see just how judged I've been.

**Acceptance Criteria:**
- [ ] Track per day: lid opens, keystrokes (if permitted), roasts received, max idle time
- [ ] Persist in UserDefaults, reset daily at midnight
- [ ] Display in 4 glass cards in popover with animated counters
- [ ] "Today's Vibe" label generated from stats (e.g., "Serial Procrastinator")

**Files:** `StatsStore.swift`, `UserStats.swift`

---

### US-4.3: Roast History
**As a** user,
**I want** to scroll through my recent roasts,
**So that** I can laugh at them again or share them.

**Acceptance Criteria:**
- [ ] Store last 100 roasts with timestamp, trigger type, personality
- [ ] Scrollable list in popover (accessible via "History" button)
- [ ] Each entry shows roast text + time + personality icon
- [ ] Tap to copy or share individual roast

**Files:** `RoastHistory.swift`, `RoastEntry.swift`

---

## Epic 5: Settings & Onboarding (Day 9-12)

### US-5.1: Settings Window
**As a** user,
**I want** to customize JudgyMac's behavior,
**So that** it judges me the way I want.

**Acceptance Criteria:**
- [ ] Open via gear icon in popover → separate Settings window
- [ ] Intensity slider (1-3): affects which templates are shown
- [ ] Per-trigger toggles: enable/disable each of the 7 triggers
- [ ] Language selector (EN default, VI when Vietnamese Mom unlocked)
- [ ] Launch at login toggle
- [ ] About section with version, links

**Files:** `SettingsView.swift`, `TriggerToggleView.swift`, `IntensitySliderView.swift`, `SettingsStore.swift`

---

### US-5.2: Onboarding Flow
**As a** first-time user,
**I want** a quick setup experience,
**So that** I understand what JudgyMac does and grant needed permissions.

**Acceptance Criteria:**
- [ ] 4-screen flow: Intro → Triggers → Personality Preview → Permissions
- [ ] Pre-select safe defaults (lid, idle, thermal ON; typing OFF)
- [ ] Show sample roasts from different personalities (soft upsell)
- [ ] Request notification permission
- [ ] Optional: Accessibility permission for typing detection
- [ ] "Let the judging begin" CTA on final screen
- [ ] Only shows once (isOnboarded flag)

**Files:** `OnboardingView.swift`

---

## Epic 6: Monetization (Day 12-15)

### US-6.1: StoreKit 2 Integration
**As a** developer,
**I want** IAP working with StoreKit 2,
**So that** users can buy personality packs and Pro subscription.

**Acceptance Criteria:**
- [ ] Load products from App Store (packs + subscription)
- [ ] Purchase flow with async/await
- [ ] Transaction listener for cross-device purchases
- [ ] Entitlement checking: `isPurchased(productID)`
- [ ] Restore purchases functionality
- [ ] StoreKit testing configuration for Xcode

**Files:** `StoreManager.swift`, `EntitlementManager.swift`, `ProductIdentifiers.swift`, `JudgyMac.storekit`

---

### US-6.2: Soft Paywall
**As a** user,
**I want** to preview locked personality packs before buying,
**So that** I know what I'm paying for.

**Acceptance Criteria:**
- [ ] Locked packs visible with lock icon in personality picker
- [ ] Each locked pack shows 3 preview roasts (read-only)
- [ ] Tap "Unlock $1.99" → StoreKit purchase flow
- [ ] Pro subscription option highlighted: "Unlock ALL packs — $9.99/year"
- [ ] 7-day free trial for subscription
- [ ] Paywall NOT shown on first launch — only after 2-3 roasts delivered

**Files:** `PaywallView.swift`, `PersonalityPickerView.swift`

---

### US-6.3: Entitlement Gating
**As a** developer,
**I want** roast engine to respect purchase state,
**So that** free users get free content and paid users get premium.

**Acceptance Criteria:**
- [ ] Free tier: "The Critic" only, 5 roasts/day, 3 triggers
- [ ] Purchased pack: unlocks that personality's templates
- [ ] Pro subscriber: all packs, 20 roasts/day, all triggers, daily summary
- [ ] RoastEngine checks EntitlementManager before selecting templates

**Files:** `RoastEngine.swift`, `EntitlementManager.swift`

---

## Epic 7: Share & Summary (Day 15-17)

### US-7.1: Daily Summary Card
**As a** user (Pro),
**I want** a shareable daily summary card,
**So that** I can share how judged I was on social media.

**Acceptance Criteria:**
- [ ] Auto-generated at end of day (or on-demand via "Share" button)
- [ ] Shows: date, key stats, funniest roast, verdict ("Impressively useless")
- [ ] Beautiful dark card design with JudgyMac branding + `judgymac.com`
- [ ] Export as PNG: 1080x1350 (Stories) + 1080x1080 (feed)
- [ ] Share via macOS share sheet
- [ ] Pro feature (free users see preview with "Upgrade to share" CTA)

**Files:** `DailySummaryGenerator.swift`, `SummaryCardView.swift`, `SummaryShareHelper.swift`

---

### US-7.2: Share Individual Roast
**As a** user,
**I want** to share a specific roast,
**So that** my friends can see how my Mac judged me.

**Acceptance Criteria:**
- [ ] "Share" button on each roast in history
- [ ] Copies formatted text: `"[roast text]" — JudgyMac (judgymac.com)`
- [ ] Optional: generate mini share card image with roast text

**Files:** `RoastHistory.swift`, `SummaryShareHelper.swift`

---

## Epic 8: Landing Page (Day 15-17, parallel with Epic 7)

### US-8.1: Landing Page — judgymac.com
**As a** potential user,
**I want** a beautiful landing page that shows me what JudgyMac does,
**So that** I'm convinced to download it.

**Acceptance Criteria:**
- [ ] Dark aesthetic matching app design
- [ ] Hero: animated face + tagline + download CTA
- [ ] Roast showcase: 3 example roasts with different personalities
- [ ] Feature grid: 7 triggers with icons
- [ ] Personality carousel: preview each judge
- [ ] Download CTA with App Store badge
- [ ] Mobile responsive
- [ ] `judgymac.com` domain configured
- [ ] All content in English

**Tool:** Framer

---

## Epic 9: Polish & Ship (Day 17-21)

### US-9.1: App Icon
**As a** user,
**I want** a recognizable app icon,
**So that** I can find JudgyMac in Spotlight/Launchpad.

**Acceptance Criteria:**
- [ ] The judgy face (🤨 style) as app icon
- [ ] All required sizes for macOS (16, 32, 128, 256, 512, 1024)
- [ ] Matches menu bar icon style

---

### US-9.2: App Store Listing
**As a** potential user browsing the App Store,
**I want** compelling screenshots and description,
**So that** I want to download JudgyMac.

**Acceptance Criteria:**
- [ ] 5 screenshots showing: popover, notification, personalities, settings, summary card
- [ ] Title: "JudgyMac — Your Mac Judges You"
- [ ] Subtitle: "Sarcastic notifications for your bad habits"
- [ ] Description in English (from PLAN.md section 2)
- [ ] Keywords optimized for ASO
- [ ] Privacy policy URL

---

### US-9.3: Performance & Quality
**As a** user,
**I want** JudgyMac to be lightweight and not drain my battery,
**So that** I can keep it running all day.

**Acceptance Criteria:**
- [ ] CPU usage < 1% idle
- [ ] Memory < 30MB
- [ ] No battery impact visible in Activity Monitor
- [ ] VoiceOver accessible
- [ ] Respects "Reduce Motion" system setting
- [ ] No crashes in 48h beta test

---

### US-9.4: Beta Testing
**As a** developer,
**I want** 50 beta testers to try JudgyMac before launch,
**So that** I catch bugs and get feedback.

**Acceptance Criteria:**
- [ ] TestFlight build distributed
- [ ] 50 testers recruited (Twitter, Reddit, Discord)
- [ ] Collect feedback: crashes, humor quality, battery, UX issues
- [ ] Fix critical bugs before App Store submission
- [ ] Collect 5+ testimonials for landing page

---

## Progress Summary

| Epic | Status | Stories | Done |
|------|--------|---------|------|
| 1. Foundation | 🟢 Done | 4 | 4/4 |
| 2. Detection | 🟢 Done | 6 | 6/6 |
| 3. Roast Engine | 🟢 Done | 6 | 6/6 |
| 4. Mood & Stats | 🟢 Done | 3 | 3/3 |
| 5. Settings & Onboarding | 🟢 Done | 2 | 2/2 |
| 6. Monetization | 🟢 Done | 3 | 3/3 |
| 7. Share & Summary | 🟢 Done | 2 | 2/2 |
| 8. Landing Page | 🔴 Not Started | 1 | 0/1 |
| 9. Polish & Ship | 🟡 In Progress | 4 | 1/4 |
| **Total** | | **31** | **26/31** |
