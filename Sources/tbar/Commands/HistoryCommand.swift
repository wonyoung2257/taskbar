import Foundation
import TBarCore

struct HistoryCommand {
    let days: Int
    let specificDate: String?

    init(arguments: [String]) throws {
        var days = 7
        var specificDate: String?

        var index = 0
        while index < arguments.count {
            switch arguments[index] {
            case "--days":
                index += 1
                guard index < arguments.count else {
                    throw ValidationError("Missing value for --days.")
                }
                days = try parsePositiveInt(arguments[index], fieldName: "Days")
            case "--date":
                index += 1
                guard index < arguments.count else {
                    throw ValidationError("Missing value for --date.")
                }
                specificDate = arguments[index]
            default:
                throw ValidationError("Unknown option '\(arguments[index])'.")
            }
            index += 1
        }

        self.days = days
        self.specificDate = specificDate
    }

    func run() throws {
        let store = TodoStore()
        let allTodos = try store.loadAll().todos
        let completedTodos = allTodos.filter { $0.done && $0.completedAt != nil }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: completedTodos) { todo -> String in
            let date = todo.completedAt ?? todo.createdAt
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }

        let sortedDates: [String]
        if let specificDate {
            sortedDates = grouped.keys.filter { $0 == specificDate }.sorted(by: >)
        } else {
            let cutoff = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: Date()))!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let cutoffStr = formatter.string(from: cutoff)
            sortedDates = grouped.keys.filter { $0 >= cutoffStr }.sorted(by: >)
        }

        guard !sortedDates.isEmpty else {
            print("No completed todos found.")
            return
        }

        let today = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()

        let yesterday = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        }()

        for dateStr in sortedDates {
            let label: String
            if dateStr == today {
                label = "\(dateStr) (오늘)"
            } else if dateStr == yesterday {
                label = "\(dateStr) (어제)"
            } else {
                label = dateStr
            }

            let todos = grouped[dateStr]!.sorted { $0.completedAt ?? $0.createdAt < $1.completedAt ?? $1.createdAt }
            print("── \(label) (\(todos.count)개 완료) ──")
            for todo in todos {
                let progress = todo.subtasks.isEmpty ? "" : " (\(todo.completedSubtaskCount)/\(todo.subtasks.count))"
                print("  ✅ \(todo.title)\(progress)")
            }
            print()
        }
    }
}
