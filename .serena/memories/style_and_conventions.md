# JudgyMac — Style & Conventions

## Language & Concurrency
- Swift 6 with **strict concurrency** (`SWIFT_STRICT_CONCURRENCY: complete`)
- Use `@Observable` (not `ObservableObject`) for state
- Use `actor` or `@MainActor` where appropriate
- Prefer value types (struct, enum) over classes when possible

## Naming Conventions
- **Files**: PascalCase matching the primary type (e.g., `RoastEngine.swift`)
- **Types**: PascalCase (structs, classes, enums, protocols)
- **Properties/Methods**: camelCase
- **Constants**: nested enum namespaces (e.g., `Constants.Roast`, `Constants.Detection`)
- **Protocols**: noun or adjective describing capability (e.g., `BehaviorDetector`)

## Code Organization
- Feature-based folder structure (Detection/, Roast/, Store/, etc.)
- Protocols in dedicated `Protocols/` subfolder
- MARK comments for section organization (e.g., `// MARK: - Setup`)
- Small, focused files (~200-400 lines)

## Data & State
- `AppState` is the single source of truth
- `SettingsStore` wraps UserDefaults with typed keys
- JSON files for roast templates (loaded at runtime)
- Immutable models (structs with let properties)

## UI
- SwiftUI for all views
- MenuBarExtra for menu bar presence
- Custom `ToastWindow` (NSWindow) for floating notifications
- Design tokens in `Theme.swift`
- Fluent Emoji 3D assets for visual identity

## Error Handling
- Explicit error handling, no silent failures
- Guard clauses for early exits
