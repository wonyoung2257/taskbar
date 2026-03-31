
import Foundation
import TBarCore

struct AddCommand {
    let title: String
    let parent: Int?
    let priority: Priority

    init(arguments: [String]) throws {
        var titleParts: [String] = []
        var parent: Int?
        var priority: Priority = .medium

        var index = 0
        while index < arguments.count {
            switch arguments[index] {
            case "--parent":
                index += 1
                guard index < arguments.count else {
                    throw ValidationError("Missing value for --parent.")
                }
                parent = try parsePositiveInt(arguments[index], fieldName: "Parent todo ID")
            case "--priority":
                index += 1
                guard index < arguments.count else {
                    throw ValidationError("Missing value for --priority.")
                }
                priority = try parsePriority(arguments[index])
            default:
                if arguments[index].hasPrefix("--") {
                    throw ValidationError("Unknown option '\(arguments[index])'.")
                }
                titleParts.append(arguments[index])
            }
            index += 1
        }

        let title = titleParts.joined(separator: " ").trimmed
        guard !title.isEmpty else {
            throw ValidationError("Title must not be empty.")
        }

        if let parent {
            guard priority == .medium else {
                throw ValidationError("--priority can only be used for top-level todos.")
            }
            self.parent = parent
        } else {
            self.parent = nil
        }

        self.title = title
        self.priority = priority
    }

    func run() throws {
        let store = TodoStore()

        if let parent {
            let subtask = try store.addSubtask(title: title, toTodoID: parent)
            print("Added subtask #\(parent).\(subtask.id): \(subtask.title)")
        } else {
            let todo = try store.addTodo(title: title, priority: priority)
            print("Added todo #\(todo.id): \(todo.title)")
        }
    }
}
