# JudgyMac — Suggested Commands

## Build & Run
```bash
# Open in Xcode
open JudgyMac.xcodeproj

# Build via xcodebuild
xcodebuild -project JudgyMac.xcodeproj -scheme JudgyMac -configuration Debug build

# Build via Swift Package Manager (verification only, not full app)
swift build
```

## Project Generation (XcodeGen)
```bash
# Regenerate Xcode project from project.yml
xcodegen generate
```

## Git
```bash
git status
git log --oneline -20
git diff
```

## System Utilities (macOS/Darwin)
```bash
ls -la
find . -name "*.swift" -not -path "./.build/*"
grep -r "pattern" --include="*.swift" JudgyMac/
```

## Useful Searches
```bash
# Find all detector implementations
grep -r "BehaviorDetector" --include="*.swift" JudgyMac/

# Find all personality packs
ls JudgyMac/Resources/Roasts/

# Count lines per module
find JudgyMac/ -name "*.swift" -exec wc -l {} + | sort -n
```

## Testing
```bash
# Run tests (when test target exists)
xcodebuild test -project JudgyMac.xcodeproj -scheme JudgyMac -destination 'platform=macOS'

# Swift package tests (limited)
swift test
```

## Formatting & Linting
```bash
# SwiftFormat (if installed)
swiftformat JudgyMac/

# SwiftLint (if installed)
swiftlint JudgyMac/
```
