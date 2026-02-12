/// Command pattern: encapsulates an action that can be executed and undone.
protocol Command: Sendable {
    var description: String { get }
    func execute()
    func undo()
}
