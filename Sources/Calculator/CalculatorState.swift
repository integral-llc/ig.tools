import SwiftUI

/// A single history entry.
struct HistoryEntry: Identifiable, Codable, Sendable {
    let id: UUID
    let expression: String
    let result: Double
    let formattedResult: String

    init(expression: String, result: Double) {
        self.id = UUID()
        self.expression = expression
        self.result = result
        self.formattedResult = NumberFormatterExt.format(result)
    }
}

/// Observable state for the calculator tool.
@Observable
@MainActor
final class CalculatorState {
    var input: String = ""
    var liveResult: String? = nil
    var isValid: Bool = false
    var history: [HistoryEntry] = []
    var copiedEntryID: UUID? = nil

    // MARK: - Window settings

    var opacity: Double {
        didSet { persistSettings() }
    }

    var alwaysOnTop: Bool {
        didSet { persistSettings() }
    }

    let context: EvalContext
    private let historyRepo = Repository<[HistoryEntry]>(key: "calculator.history")
    private let variablesRepo = Repository<[String: Double]>(key: "calculator.variables")
    private let memoryRepo = Repository<Double>(key: "calculator.memory")
    private let settingsRepo = Repository<CalculatorSettings>(key: "calculator.settings")

    init() {
        let savedVars = variablesRepo.load() ?? [:]
        let savedMemory = memoryRepo.load() ?? 0
        self.context = EvalContext(variables: savedVars, memory: savedMemory)
        self.history = historyRepo.load() ?? []

        let settings = settingsRepo.load() ?? CalculatorSettings()
        self.opacity = settings.opacity
        self.alwaysOnTop = settings.alwaysOnTop
    }

    private func persistSettings() {
        settingsRepo.save(CalculatorSettings(opacity: opacity, alwaysOnTop: alwaysOnTop))
    }

    // MARK: - Live evaluation

    func evaluateInput() {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            liveResult = nil
            isValid = false
            return
        }

        // Use a copy of context so live eval doesn't mutate variables
        let ctx = context.copy()
        do {
            let result = try Evaluator.evaluate(trimmed, context: ctx)
            liveResult = NumberFormatterExt.format(result)
            isValid = true
        } catch {
            liveResult = "N/A"
            isValid = false
        }
    }

    // MARK: - Submit

    func submit() {
        guard isValid else { return }
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        do {
            let result = try Evaluator.evaluate(trimmed, context: context)
            let entry = HistoryEntry(expression: trimmed, result: result)
            history.insert(entry, at: 0)
            if history.count > 200 { history = Array(history.prefix(200)) }
            persistHistory()
            persistVariables()
            input = ""
            liveResult = nil
            isValid = false
        } catch {
            assertionFailure("Evaluation failed after validation: \(error)")
            print("Unexpected evaluation error: \(error)")
        }
    }

    // MARK: - Memory operations

    func memoryClear()  { context.memory = 0; persistMemory() }
    func memoryRecall() { input = NumberFormatterExt.format(context.memory) ; evaluateInput() }
    func memoryAdd()    { if let val = currentValue { context.memory += val; persistMemory() } }
    func memorySub()    { if let val = currentValue { context.memory -= val; persistMemory() } }
    func memoryStore()  { if let val = currentValue { context.memory = val; persistMemory() } }

    var formattedMemory: String { NumberFormatterExt.format(context.memory) }

    private var currentValue: Double? {
        try? Evaluator.evaluate(input.trimmingCharacters(in: .whitespaces), context: context.copy())
    }

    // MARK: - Clipboard

    private var copyIndicatorTasks: [UUID?: Task<Void, Never>] = [:]

    func copyResult(_ text: String, entryID: UUID? = nil) {
        ClipboardService.copy(text)
        copiedEntryID = entryID

        // Cancel existing task for this entry
        copyIndicatorTasks[entryID]?.cancel()

        // Create new task
        copyIndicatorTasks[entryID] = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(1.5))
                if !Task.isCancelled && copiedEntryID == entryID {
                    copiedEntryID = nil
                }
            } catch {
                // Task was cancelled
            }
            copyIndicatorTasks.removeValue(forKey: entryID)
        }
    }

    // MARK: - Clear

    func clearHistory() {
        history.removeAll()
        persistHistory()
    }

    // MARK: - Variable management

    var variableNames: Set<String> {
        Set(context.variables.keys)
    }

    var sortedVariables: [(name: String, value: Double)] {
        context.variables.sorted { $0.key < $1.key }.map { (name: $0.key, value: $0.value) }
    }

    func setVariable(_ name: String, _ value: Double) {
        context.variables[name] = value
        persistVariables()
    }

    func removeVariable(_ name: String) {
        context.variables.removeValue(forKey: name)
        persistVariables()
    }

    // MARK: - Persistence

    private func persistHistory() { historyRepo.save(history) }
    private func persistVariables() { variablesRepo.save(context.variables) }
    private func persistMemory() { memoryRepo.save(context.memory) }
}
