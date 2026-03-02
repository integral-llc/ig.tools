# AGENTS.md

## Build/Lint/Test Commands

### Build Commands
```bash
# Build using Swift Package Manager
swift build -c release

# Or use the build script to create a .app bundle
./build.sh

# Build and install to /Applications
./build.sh --install
```

### Test Commands
```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter LexerTests
swift test --filter ParserTests
swift test --filter EvaluatorTests
swift test --filter CalculatorIntegrationTests
swift test --filter PercentageVariableTests
swift test --filter LanguageHintsTests
swift test --filter LayoutSwitcherPipelineTests

# Run a specific test
swift test --filter "LexerTests/basicTokens"
swift test --filter "ParserTests/simpleParse"
```

### Run the Application
```bash
# After building with SwiftPM
./.build/release/IGTools

# Or after building with build.sh
open "build/IG Tools.app"
```

## Code Style Guidelines

### Naming Conventions
- Use descriptive names with clear separation of concerns
- Follow Swift standard library naming conventions
- Use camelCase for variables and functions
- Use PascalCase for types and protocols
- Use UPPER_SNAKE_CASE for constants

### Imports and Organization
- Import modules in alphabetical order
- Group related functionality with MARK comments
- Use extensions for protocol conformances when appropriate
- Separate public and private APIs clearly

### Types
- Use explicit types when not obvious from context
- Prefer structs over classes when no identity or inheritance needed
- Use @Observable for state classes that need SwiftUI integration
- Use @MainActor for UI-related code and tool implementations
- Include Sendable conformance where appropriate for thread safety

### Error Handling
- Calculator uses throws for expression evaluation errors
- Use Swift error handling patterns (do/catch, throws)
- Create specific error types for different error conditions

### Formatting
- Use 4-space indentation
- Keep lines under 120 characters when possible
- Place opening braces on the same line as declarations
- Add a blank line after MARK comments
- Put trailing commas in arrays/dictionaries for easier diffs

### Comments and Documentation
- Document public APIs with triple-slash comments
- Use inline comments sparingly and only when code isn't self-explanatory
- Keep comments up to date with code changes

### Testing Patterns
- Organize tests by component (LexerTests, ParserTests, etc.)
- Use Testing framework annotations (@Test, @Suite)
- Test both happy paths and error conditions
- Provide clear, descriptive test names
- Use #expect assertions for test validation

## Architecture Patterns

### Tool System (Strategy Pattern)
- Each tool conforms to the Tool protocol
- Tools provide unique ID, name, and SF Symbol icon
- Tools implement makeView() and makeSettingsView() methods
- Window opacity and always-on-top settings are tool-specific
- Frame positions are automatically persisted

### Calculator Components
1. Lexer (Sources/Calculator/Lexer/): Tokenizes input text
2. Parser (Sources/Calculator/Parser/): Builds AST from tokens
3. Evaluator (Sources/Calculator/Evaluator/): Evaluates AST nodes
4. State Management (CalculatorState.swift): Manages state, history, variables, memory

### Layout Switcher Components
1. LayoutSwitcherState (Sources/LayoutSwitcher/): CGEvent tap + word detection logic
2. LayoutMap (Sources/LayoutSwitcher/LayoutMap.swift): QWERTY↔ЙЦУКЕН key mapping
3. LanguageHints (Sources/LayoutSwitcher/LanguageHints.swift): Curated word/prefix tables for language detection
4. InputSourceManager (Sources/LayoutSwitcher/InputSourceManager.swift): macOS TIS API for layout switching

### Persistence
- All state persisted to UserDefaults via Repository class
- History, variables, and memory are automatically saved
- Window positions and tool settings are preserved
- Use appropriate Repository generic types for each data type

### Best Practices
- Use copy() method on EvalContext for live evaluation isolation
- Limit history to reasonable size (200 entries)
- Handle edge cases gracefully (division by zero, invalid input)
- Follow thread safety patterns with @MainActor and Sendable
- Use computed properties for derived values rather than stored state