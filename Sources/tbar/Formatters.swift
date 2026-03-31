import TBarCore

enum TBarFormatter {
    private static var icons: PriorityIcons {
        TBarPreferences.load(from: TBarConfig().directoryURL).priorityIcons
    }

    static func renderTodos(_ todos: [Todo]) -> String {
        todos.map(renderTodo).joined(separator: "\n")
    }

    static func renderTodo(_ todo: Todo) -> String {
        var lines = [renderTodoLine(todo)]

        for index in todo.subtasks.indices {
            let subtask = todo.subtasks[index]
            let branch = index == todo.subtasks.count - 1 ? "└─" : "├─"
            lines.append("     \(branch) \(checkbox(for: subtask.done)) \(subtask.title)")
        }

        return lines.joined(separator: "\n")
    }

    private static func renderTodoLine(_ todo: Todo) -> String {
        let progress = todo.subtasks.isEmpty ? "" : " (\(todo.completedSubtaskCount)/\(todo.subtasks.count))"
        return "  \(todo.id). [\(statusIcon(for: todo))] \(todo.title)\(progress)"
    }

    private static func statusIcon(for todo: Todo) -> String {
        let ic = icons
        if todo.done {
            return "✅"
        }

        switch todo.priority {
        case .high:
            return ic.high
        case .medium:
            return ic.medium
        case .low:
            return ic.low
        }
    }

    private static func checkbox(for isDone: Bool) -> String {
        isDone ? "[x]" : "[ ]"
    }
}
