import Foundation

public struct PriorityIcons: Codable, Equatable, Sendable {
    public var high: String
    public var medium: String
    public var low: String

    public init(high: String, medium: String, low: String) {
        self.high = high
        self.medium = medium
        self.low = low
    }

    public static let presets: [(name: String, icons: PriorityIcons)] = [
        ("Flame", PriorityIcons(high: "🔥", medium: "📌", low: "💤")),
        ("Color", PriorityIcons(high: "🔴", medium: "🟡", low: "🔵")),
        ("Arrow", PriorityIcons(high: "⬆️", medium: "➡️", low: "⬇️")),
        ("Simple", PriorityIcons(high: "‼️", medium: "❕", low: "▫️")),
    ]

    public static let `default` = presets[1].icons // Color
}

public struct TBarPreferences: Codable, Equatable, Sendable {
    public var priorityIcons: PriorityIcons

    public init(priorityIcons: PriorityIcons = .default) {
        self.priorityIcons = priorityIcons
    }

    public static func load(from directoryURL: URL) -> TBarPreferences {
        let url = directoryURL.appendingPathComponent("config.json")
        guard let data = try? Data(contentsOf: url),
              let prefs = try? JSONDecoder().decode(TBarPreferences.self, from: data) else {
            return TBarPreferences()
        }
        return prefs
    }

    public func save(to directoryURL: URL) throws {
        let url = directoryURL.appendingPathComponent("config.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url, options: .atomic)
    }
}
