# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IG Tools is a macOS menu bar application built with SwiftUI that provides floating utility tools. Currently features a calculator with expression parsing, variable management, and history tracking.

## Build and Run

### Build the Application
```bash
# Build using Swift Package Manager
swift build -c release

# Or use the build script to create a .app bundle
./build.sh
```

### Run Tests
```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter LexerTests
swift test --filter ParserTests
swift test --filter EvaluatorTests
swift test --filter CalculatorIntegrationTests
swift test --filter PercentageVariableTests

# Run a specific test
swift test --filter "LexerTests/basicTokens"
```

### Run the Application
```bash
# After building with SwiftPM
./.build/release/IGTools

# Or after building with build.sh
open "build/IG Tools.app"
```

## Architecture

### Tool System (Strategy Pattern)
The application uses a plugin-like architecture where each utility is a "tool" conforming to the `Tool` protocol:

- **Tool Protocol** (`Sources/Core/Protocols/Tool.swift`): Defines the interface for all tools
- **ToolRegistry** (`Sources/Core/ToolRegistry.swift`): Discovers and manages available tools
- **ToolWindowManager** (`Sources/Core/ToolWindowManager.swift`): Manages floating windows for each tool

Each tool provides:
- Unique ID, name, and SF Symbol icon
- View and settings view via SwiftUI
- Window opacity and "always on top" settings
- Automatic frame persistence

### Calculator Architecture
The calculator is a sophisticated expression evaluator with:

1. **Lexer** (`Sources/Calculator/Lexer/`): Tokenizes input text into tokens (numbers, operators, functions, variables)
2. **Parser** (`Sources/Calculator/Parser/`): Builds an Abstract Syntax Tree (AST) from tokens
3. **Evaluator** (`Sources/Calculator/Evaluator/`): Evaluates AST nodes with variable context and function implementations
4. **State Management** (`Sources/Calculator/CalculatorState.swift`): Manages calculator state, history, variables, and memory

Key features:
- Live evaluation as you type
- Variable assignment and management (`$x = 5`, `$y = $x * 2`)
- Function support (`sin`, `cos`, `sqrt`, `log`, etc.)
- Memory operations (M+, M-, MR, MC, MS)
- History tracking with copy-to-clipboard
- Syntax highlighting in input field

### Percentage System
The calculator has special support for percentages:
- Standalone: `30%` evaluates to `0.3`
- Trailing: `5 + 30%` evaluates to `6.5` (adds 30% of 5)
- Variables can be marked as percentage type, displayed as `30%` but stored as `0.3`

### Persistence
All state is persisted to `UserDefaults` via the `Repository` class:
- Calculator history, variables, and memory
- Window positions for each tool
- Tool-specific settings (opacity, always on top)

### Dependencies
- **KeyboardShortcuts** (Sindre Sorhus): For global hotkey support

## Adding New Tools

To add a new tool:

1. Create a new directory under `Sources/` for your tool
2. Create a struct conforming to `Tool` protocol
3. Implement the required properties and methods
4. Register the tool in `AppDelegate.setupRegistry()`
5. Add any necessary settings and state management

Example structure:
```swift
struct MyTool: Tool {
    let id = "mytool"
    let name = "My Tool"
    let icon = "star"

    @MainActor var opacity: Double { state.opacity }
    @MainActor var alwaysOnTop: Bool { state.alwaysOnTop }

    @MainActor
    func makeView() -> AnyView {
        AnyView(MyToolView(state: state))
    }

    @MainActor
    func makeSettingsView() -> AnyView {
        AnyView(MyToolSettingsView(state: state))
    }
}
```

## Testing

Tests are organized by component:
- `LexerTests`: Tokenization logic
- `ParserTests`: AST construction
- `EvaluatorTests`: Expression evaluation
- `CalculatorIntegrationTests`: End-to-end calculator functionality
- `PercentageVariableTests`: Percentage variable handling

Run individual test suites:
```bash
swift test --filter LexerTests
swift test --filter ParserTests
swift test --filter EvaluatorTests
swift test --filter CalculatorIntegrationTests
swift test --filter PercentageVariableTests
```

## Code Style and Conventions

- **MainActor**: All UI-related code and tool implementations use `@MainActor`
- **Sendable**: Protocol conformances include `Sendable` where appropriate for thread safety
- **Observable**: State classes use `@Observable` for SwiftUI integration
- **Naming**: Descriptive names with clear separation of concerns
- **Error Handling**: Calculator uses `throws` for expression evaluation errors

## Common Development Tasks

### Debugging
- Use `print()` statements for quick debugging
- Check Console.app for runtime logs
- Use Xcode debugger when needed

### Adding New Functions to Calculator
1. Add function name to `Functions.swift` in the `functions` dictionary
2. Implement the function logic
3. Add tests to `EvaluatorTests.swift`

### Adding New Operators
1. Add token type to `Token.swift`
2. Update `Lexer.swift` to recognize the operator
3. Update `Parser.swift` to handle precedence and associativity
4. Update `Evaluator.swift` to evaluate the operator
5. Add tests for the new operator

### Modifying UI Components
- Calculator view: `CalculatorView.swift`
- Settings view: `CalculatorSettingsView.swift`
- History view: `HistoryView.swift`
- Variables view: `VariablesView.swift`

### Working with State
- Calculator state: `CalculatorState.swift`
- Shared state patterns use `@Observable` classes
- State persistence uses `UserDefaults` via `Repository` class