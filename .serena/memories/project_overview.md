# JudgyMac — Project Overview

## Purpose
JudgyMac is a macOS menu bar app that monitors user behavior and "roasts" them with humorous, personality-driven text notifications. Think of it as a behavioral companion — it tracks daily patterns (lid open/close, idle time, late night usage, thermal state) and delivers contextual, culturally-aware roasts.

## Business Model
- **Freemium + IAP**: Free tier with limited personalities, paid full version unlocks all packs
- **Target**: macOS 14+ (Sonoma), Apple Silicon
- **Pricing**: ~$5 one-time purchase (StoreKit 2)
- **Competitive positioning**: vs SlapMac (physical gag) — JudgyMac is deeper (text, personality, cultural humor, shareability)

## Tech Stack
- **Language**: Swift 6 (strict concurrency)
- **UI**: SwiftUI + MenuBarExtra
- **Build**: Xcode project (project.yml via XcodeGen)
- **Monetization**: StoreKit 2
- **Min deployment**: macOS 14.0
- **Bundle ID**: com.judgymac.app

## Key Features
- Menu bar emoji that changes based on mood
- Behavior detection (lid, idle, thermal, time-of-day, CPU)
- Roast engine with personality packs (Vietnamese Mom, Shakespeare, Drill Sergeant, Therapist, Toxic Boss, The Critic)
- Multi-language support (en, vi)
- Toast notifications for roasts
- Daily summary cards (shareable)
- History view
- Onboarding flow
- Settings with trigger toggles and intensity control
