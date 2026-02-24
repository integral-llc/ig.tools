# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IG Tools is a macOS 14+ menu bar application built with SwiftUI that provides floating utility tools. Currently features a calculator with expression parsing, variable management, and history tracking. Uses Swift 6 strict concurrency.

## Build and Run

```bash
swift build -c release          # Build with SwiftPM
./build.sh                      # Build .app bundle (into build/IG Tools.app)
./.build/release/IGTools        # Run after SwiftPM build
open "build/IG Tools.app"       # Run after build.sh

swift test                                      # Run all tests
swift test --filter LexerTests                  # Run a test suite
swift test --filter "LexerTests/basicTokens"    # Run a single test
```

Test suites: `LexerTests`, `ParserTests`, `EvaluatorTests`, `CalculatorIntegrationTests`, `PercentageVariableTests`

Tests use **Swift Testing** framework (`@Test`, `@Suite`, `#expect`), not XCTest.

## Architecture

### Tool System (Strategy Pattern)
Each utility is a "tool" conforming to the `Tool` protocol (`Sources/Core/Protocols/Tool.swift`):
- `ToolRegistry` (`Sources/Core/ToolRegistry.swift`) — discovers and manages tools
- `ToolWindowManager` (`Sources/Core/ToolWindowManager.swift`) — manages floating `NSPanel` windows per tool
- Tools are registered in `AppDelegate.setupRegistry()`
- Each tool provides its own view, settings view, opacity, and always-on-top setting
- Window frames auto-persist via `Repository<SavedFrame>`

The app entry point (`Sources/App/IGToolsApp.swift`) is a `MenuBarExtra` that toggles tool windows.

### Calculator Pipeline
The calculator follows a classic **Lexer → Parser → Evaluator** pipeline:

1. **Lexer** (`Sources/Calculator/Lexer/`) — tokenizes input into `Token` values
2. **Parser** (`Sources/Calculator/Parser/`) — builds an AST (`ASTNode` tree) from tokens
3. **Evaluator** (`Sources/Calculator/Evaluator/`) — tree-walks the AST with an `EvalContext` (variables, memory, functions)

`CalculatorState` orchestrates the pipeline: live-evaluates on keystroke (using a copied context to avoid side effects), commits on submit (mutating the real context).

### Percentage System
- Standalone: `30%` → `0.3`
- Trailing: `5 + 30%` → `6.5` (adds 30% of 5)
- Variables track percentage type via `VariableValue` enum (`.number` vs `.percentage`), displayed as `30%` but stored as `0.3`

### Persistence
`Repository<T: Codable>` (`Sources/Core/Persistence.swift`) — generic JSON-encoded `UserDefaults` storage. Used for history, variables, memory, settings, and window frames.

### Dependencies
- **KeyboardShortcuts** (Sindre Sorhus) — global hotkey support

## Adding New Tools

1. Create a new directory under `Sources/` for your tool
2. Create a struct conforming to `Tool` protocol (ID, name, icon, view, settings view)
3. Register in `AppDelegate.setupRegistry()`
4. Use `Repository<T>` for any persistent state

## Adding Calculator Functions/Operators

**New function**: Add to the `functions` dictionary in `Sources/Calculator/Evaluator/Functions.swift`, then add tests to `Tests/EvaluatorTests.swift`.

**New operator**: Update `Token.swift` → `Lexer.swift` → `Parser.swift` (handle precedence) → `Evaluator.swift`, then add tests.

## Code Conventions

- **Swift 6 concurrency**: `@MainActor` on all UI code and tool implementations; `Sendable` conformance where needed
- **`@Observable`** for state classes (SwiftUI integration)
- **`nonisolated(unsafe)`** used sparingly for bridging to non-Sendable types (e.g., `UserDefaults`)
- **4-space indentation**, opening braces on same line
- Use `EvalContext.copy()` for live evaluation to isolate side effects from the real context
