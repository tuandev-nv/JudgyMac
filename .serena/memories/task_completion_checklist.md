# JudgyMac — Task Completion Checklist

When completing a task, verify the following:

## Code Quality
- [ ] Swift 6 strict concurrency — no warnings
- [ ] Follows naming conventions (PascalCase types, camelCase properties)
- [ ] Small focused functions (<50 lines)
- [ ] Small focused files (<800 lines)
- [ ] No hardcoded values — use Constants enum
- [ ] Immutable patterns (struct, let)
- [ ] Proper error handling (no silent failures)

## Build Verification
- [ ] `swift build` succeeds (basic check)
- [ ] `xcodebuild build` succeeds (full check)
- [ ] No compiler warnings

## Architecture
- [ ] New detectors implement `BehaviorDetector` protocol
- [ ] State changes go through `AppState`
- [ ] New roast packs follow JSON template format
- [ ] UI uses SwiftUI and Design/ components

## Before Commit
- [ ] No hardcoded secrets
- [ ] No debug/print statements left behind
- [ ] File organization matches feature-based structure
- [ ] PLAN.md updated if scope changes
