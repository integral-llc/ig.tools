import Foundation

/// Repository pattern: typed UserDefaults storage for any Codable value.
struct Repository<T: Codable>: Sendable {
    let key: String
    nonisolated(unsafe) private let defaults: UserDefaults

    init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func load() -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func save(_ value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    func delete() {
        defaults.removeObject(forKey: key)
    }
}
