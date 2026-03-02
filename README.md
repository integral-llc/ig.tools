# IG Tools

A macOS 14+ menu bar app with floating utility windows. Built with SwiftUI and Swift 6 strict concurrency.

## Tools

### Calculator

A floating calculator with expression parsing, variables, and history.

- Live evaluation on every keystroke
- Variables: `x = 42`, then use `x * 2`
- Percentage syntax: `5 + 30%` = `6.5` (adds 30% of 5)
- Built-in functions: `sin`, `cos`, `sqrt`, `log`, `abs`, `min`, `max`, `pow`, `round`, `ceil`, `floor`
- Constants: `pi`, `e`
- Factorial: `5!` = `120`
- Memory: store and recall values
- Expression history with re-evaluation

### Layout Switcher

Auto-detects when you type on the wrong keyboard layout (English / Russian) and corrects it. Similar to Punto Switcher.

- Monitors keystrokes via macOS CGEvent tap
- Detects wrong layout using curated word/prefix tables + NSSpellChecker
- Replaces typed text and switches the input source automatically
- Handles multi-word phrases
- Works with short common words (`nfr` -> `tak`, `crsch` -> `who`)
- Configurable minimum word length, sound feedback

### Text Shortcuts

Expand custom abbreviations into full text snippets as you type.

## Requirements

- macOS 14.0+
- Xcode 16+ / Swift 6.0+
- Accessibility permission (for Layout Switcher keystroke monitoring)

## Build

```bash
# Build with Swift Package Manager
swift build -c release

# Build .app bundle
./build.sh

# Build and install to /Applications
./build.sh --install

# Run tests
swift test
```

## Project Structure

```
Sources/
  App/                  # Entry point, AppDelegate, menu bar
  Core/                 # Tool protocol, registry, window manager, persistence
  Calculator/           # Lexer -> Parser -> Evaluator pipeline
    Lexer/              # Tokenizer
    Parser/             # AST builder
    Evaluator/          # Tree-walking evaluator with functions & variables
  LayoutSwitcher/       # Keyboard layout detection and auto-switching
  TextShortcuts/        # Text expansion engine
  Shared/               # Shared utilities
Tests/                  # Swift Testing framework tests
Resources/              # Info.plist, app icon assets
```

## Architecture

Each utility is a **Tool** (Strategy pattern) conforming to the `Tool` protocol. Tools are registered in `AppDelegate` and managed by `ToolWindowManager`, which creates floating `NSPanel` windows. All state is persisted via `Repository<T: Codable>` (JSON-encoded UserDefaults).

The app runs as a `MenuBarExtra` with no dock icon (`LSUIElement = true`).

## Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (Sindre Sorhus) -- global hotkey support

## License

Private.
