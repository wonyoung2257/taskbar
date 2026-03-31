import Foundation

/// Priority levels supported by top-level todos.
public enum Priority: String, Codable, CaseIterable, Comparable, Sendable {
    case high
    case medium
    case low

    /// A stable sort order that places higher priority items first.
    public var sortOrder: Int {
        switch self {
        case .high:
            return 0
        case .medium:
            return 1
        case .low:
            return 2
        }
    }

    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

/// A subtask belonging to a top-level todo.
public struct SubTask: Codable, Equatable, Sendable {
    public let id: Int
    public var title: String
    public var done: Bool

    /// Creates a new subtask value.
    public init(id: Int, title: String, done: Bool = false) {
        self.id = id
        self.title = title
        self.done = done
    }
}

/// A top-level todo item stored by the app and CLI.
public struct Todo: Codable, Equatable, Sendable {
    public let id: Int
    public var title: String
    public var priority: Priority
    public var done: Bool
    public var completedAt: Date?
    public let createdAt: Date
    public var nextSubtaskId: Int
    public var subtasks: [SubTask]

    /// Creates a new todo value.
    public init(
        id: Int,
        title: String,
        priority: Priority = .medium,
        done: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        nextSubtaskId: Int = 1,
        subtasks: [SubTask] = []
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.done = done
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.nextSubtaskId = nextSubtaskId
        self.subtasks = subtasks
    }

    /// Whether this todo was completed before today (system timezone).
    public var isCompletedBeforeToday: Bool {
        guard done, let completedAt else { return false }
        return completedAt < Calendar.current.startOfDay(for: Date())
    }

    /// The number of completed subtasks for the todo.
    public var completedSubtaskCount: Int {
        subtasks.filter(\.done).count
    }
}

/// Root JSON payload persisted to disk.
public struct TodoData: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var todos: [Todo]
    public var nextId: Int

    /// Creates a new root payload.
    public init(
        version: Int = TodoData.currentVersion,
        todos: [Todo] = [],
        nextId: Int = 1
    ) {
        self.version = version
        self.todos = todos
        self.nextId = nextId
    }
}
