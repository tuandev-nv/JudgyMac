# JudgyMac — Architecture

## Codebase Structure

```
JudgyMac/
├── App/                    # App entry point, lifecycle
│   ├── JudgyMacApp.swift   # @main SwiftUI App with MenuBarExtra
│   ├── AppDelegate.swift   # NSApplicationDelegate
│   ├── AppState.swift      # Central @Observable state (mood, roast, stats, settings)
│   └── OnboardingView.swift
├── Detection/              # Behavior monitoring
│   ├── Protocols/
│   │   └── BehaviorDetector.swift  # Protocol: start(onEvent:), stop(), isRunning
│   ├── DetectionCoordinator.swift  # Orchestrates all detectors
│   ├── LidDetector.swift
│   ├── IdleDetector.swift
│   ├── ThermalDetector.swift
│   ├── TimeOfDayDetector.swift
│   └── CPUMonitor.swift
├── Models/
│   ├── BehaviorEvent.swift  # Struct with TriggerType enum
│   ├── Mood.swift           # Enum with emoji/icon mappings
│   ├── RoastEntry.swift
│   └── UserStats.swift
├── Roast/                   # Roast generation
│   ├── RoastEngine.swift    # Loads packs, generates roasts with context
│   ├── PersonalityPack.swift # Personality definition + templates
│   ├── RoastTemplate.swift
│   ├── RoastPresenter.swift
│   └── RoastCooldownTracker.swift
├── MenuBar/                 # UI layer
│   ├── MenuBarView.swift
│   ├── ToastWindow.swift
│   ├── HistoryView.swift
│   └── MoodEngine.swift
├── Design/                  # Design system
│   ├── Theme.swift
│   ├── GlassCard.swift
│   ├── RoastBubble.swift
│   └── FluentEmoji.swift    # Fluent Emoji 3D assets
├── Settings/
│   ├── SettingsView.swift
│   └── SettingsWindowController.swift
├── Persistence/
│   ├── RoastHistory.swift
│   ├── StatsStore.swift
│   └── SettingsStore.swift  # UserDefaults wrapper
├── Store/                   # StoreKit 2 IAP
│   ├── StoreManager.swift
│   ├── EntitlementManager.swift
│   ├── PaywallView.swift
│   └── ProductIdentifiers.swift
├── Summary/
│   ├── DailySummaryGenerator.swift
│   ├── SummaryCardView.swift
│   └── SummaryShareHelper.swift
├── Utilities/
│   └── Constants.swift
├── Resources/
│   ├── Roasts/en/*.json     # English personality packs
│   ├── Roasts/vi/*.json     # Vietnamese personality packs
│   └── Emoji/3D/, Flat/, MenuBar/  # Fluent Emoji assets
└── i18n/                    # Localization (future)
```

## Core Flow
1. `DetectionCoordinator` starts all `BehaviorDetector`s
2. Detectors emit `BehaviorEvent` when behavior is detected
3. `AppState.handleEvent(_:)` receives events
4. `RoastEngine.generateRoast(for:)` picks a template from the active `PersonalityPack`
5. `RoastPresenter` / `ToastWindow` displays the roast
6. `MoodEngine` updates menu bar emoji based on activity

## Key Design Patterns
- **Protocol-based detection**: `BehaviorDetector` protocol for all detectors
- **Observable state**: `AppState` as central `@Observable` class
- **Template engine**: JSON-based roast templates with variable interpolation
- **Cooldown system**: `RoastCooldownTracker` prevents spam
