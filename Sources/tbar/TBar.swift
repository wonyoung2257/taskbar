import Darwin
import Foundation
import TBarCore

struct ValidationError: Error, LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

struct TodoReference {
    let todoId: Int
    let subtaskId: Int?

    init(_ rawValue: String) throws {
        let components = rawValue.split(separator: ".", omittingEmptySubsequences: false)

        switch components.count {
        case 1:
            guard let todoId = Int(components[0]), todoId > 0 else {
                throw ValidationError("Expected a positive todo ID or parent.subtask reference.")
            }
            self.todoId = todoId
            self.subtaskId = nil
        case 2:
            guard
                let todoId = Int(components[0]),
                let subtaskId = Int(components[1]),
                todoId > 0,
                subtaskId > 0
            else {
                throw ValidationError("Expected a positive todo ID or parent.subtask reference.")
            }
            self.todoId = todoId
            self.subtaskId = subtaskId
        default:
            throw ValidationError("Expected a positive todo ID or parent.subtask reference.")
        }
    }

    var displayValue: String {
        if let subtaskId {
            return "\(todoId).\(subtaskId)"
        }
        return "\(todoId)"
    }
}

@main
struct TBar {
    static let version = "0.1.0"

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch let error as ValidationError {
            fputs("Error: \(error.message)\n", stderr)
            Darwin.exit(1)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            fputs("Error: \(message)\n", stderr)
            Darwin.exit(1)
        }
    }

    static func run(arguments: [String]) throws {
        guard let command = arguments.first else {
            print(usage)
            return
        }

        let tail = Array(arguments.dropFirst())
        switch command {
        case "--version", "-v":
            print(TBar.version)
        case "--help", "-h", "help":
            print(usage)
        case "add":
            try AddCommand(arguments: tail).run()
        case "list":
            try ListCommand(arguments: tail).run()
        case "done":
            try DoneCommand(arguments: tail).run()
        case "undone":
            try UndoneCommand(arguments: tail).run()
        case "delete":
            try DeleteCommand(arguments: tail).run()
        case "priority":
            try PriorityCommand(arguments: tail).run()
        case "search":
            try SearchCommand(arguments: tail).run()
        default:
            throw ValidationError("Unknown command '\(command)'.\n\n\(usage)")
        }
    }

    private static let usage = """
    Usage: tbar <command> [options]

    Commands:
      add <title> [--priority high|medium|low]
      add <title> --parent <todoId>
      list [--all] [--priority high|medium|low]
      done <id>
      undone <id>
      delete <id>
      priority <id> <high|medium|low>
      search <keyword>
      --version
    """
}

func parsePriority(_ rawValue: String) throws -> Priority {
    guard let priority = Priority(rawValue: rawValue.lowercased()) else {
        throw ValidationError("Priority must be one of: high, medium, low.")
    }
    return priority
}

func parsePositiveInt(_ rawValue: String, fieldName: String) throws -> Int {
    guard let value = Int(rawValue), value > 0 else {
        throw ValidationError("\(fieldName) must be a positive integer.")
    }
    return value
}

func requireNoExtraArguments(_ arguments: [String], commandName: String) throws {
    guard arguments.isEmpty else {
        throw ValidationError("Unexpected arguments for '\(commandName)': \(arguments.joined(separator: " "))")
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
