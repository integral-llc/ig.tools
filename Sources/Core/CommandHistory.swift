import Observation

/// Maintains an undo stack of executed commands.
@Observable
@MainActor
final class CommandHistory {
    private(set) var stack: [any Command] = []
    private let maxSize: Int

    init(maxSize: Int = 100) {
        self.maxSize = maxSize
    }

    func execute(_ command: any Command) {
        command.execute()
        stack.append(command)
        if stack.count > maxSize {
            stack.removeFirst()
        }
    }

    func undoLast() {
        guard let command = stack.popLast() else { return }
        command.undo()
    }
}
