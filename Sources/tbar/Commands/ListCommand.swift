
import TBarCore

struct ListCommand {
    let all: Bool
    let priority: Priority?

    init(arguments: [String]) throws {
        var all = false
        var priority: Priority?

        var index = 0
        while index < arguments.count {
            switch arguments[index] {
            case "--all":
                all = true
            case "--priority":
                index += 1
                guard index < arguments.count else {
                    throw ValidationError("Missing value for --priority.")
                }
                priority = try parsePriority(arguments[index])
            default:
                throw ValidationError("Unknown option '\(arguments[index])'.")
            }
            index += 1
        }

        self.all = all
        self.priority = priority
    }

    func run() throws {
        let store = TodoStore()
        var todos = try store.loadAll().todos

        if let priority {
            todos = todos.filter { $0.priority == priority }
        }
        if !all {
            todos = todos.filter { !$0.isCompletedBeforeToday }
        }

        guard !todos.isEmpty else {
            print("No todos found.")
            return
        }

        print(TBarFormatter.renderTodos(todos))
    }
}
