# CLAUDE.md - iOS SwiftUI Development Guide

## Project Overview
iOS app built with SwiftUI and Swift 6.1, targeting iOS 17.0+

## Development Setup
```bash
# Open workspace
open Argus.xcworkspace

# Build project
xcodebuild -project Argus.xcodeproj -scheme Argus -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -project Argus.xcodeproj -scheme Argus -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
xcodebuild clean -project Argus.xcodeproj -scheme Argus
```

## Code Standards
- Swift 6.1 strict concurrency enabled
- Use `@MainActor` for UI-related classes
- Prefer `async/await` over completion handlers
- Use `@Observable` macro for state management
- Follow SwiftUI declarative patterns

## Architecture
- MV+Store
- Repository pattern for data access
- Use cases for business logic
- Stores for state management
- Clean Architecture principles

## Testing
```bash
# Unit tests
swift test

# UI tests
xcodebuild test -project Argus.xcodeproj -scheme Argus -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Code Quality
```bash
# SwiftLint (if available)
swiftlint

# Swift format (if available)
swift-format --in-place **/*.swift
```

## Key Patterns
- Use `@State` for local view state
- Use `@Observable` for shared state objects
- Inject dependencies via initializers
- Handle errors with custom `AppError` types
- Use `Task` for async operations in views

## Debugging
- Use `print()` statements sparingly
- Leverage Xcode breakpoints and console
- Use `os_log` for production logging
- Test on both simulator and device

## Common Commands
- Build: `⌘+B`
- Run: `⌘+R`
- Test: `⌘+U`
- Clean: `⌘+Shift+K`
