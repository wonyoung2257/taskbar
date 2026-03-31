
import TBarCore

struct DoneCommand {
    let reference: String

    init(arguments: [String]) throws {
        guard let reference = arguments.first else {
            throw ValidationError("Missing todo reference.")
        }
        try requireNoExtraArguments(Array(arguments.dropFirst()), commandName: "done")
        self.reference = reference
    }

    func run() throws {
        try updateDoneState(for: reference, isDone: true)
    }
}

struct UndoneCommand {
    let reference: String

    init(arguments: [String]) throws {
        guard let reference = arguments.first else {
            throw ValidationError("Missing todo reference.")
        }
        try requireNoExtraArguments(Array(arguments.dropFirst()), commandName: "undone")
        self.reference = reference
    }

    func run() throws {
        try updateDoneState(for: reference, isDone: false)
    }
}

private func updateDoneState(for rawReference: String, isDone: Bool) throws {
    let reference = try TodoReference(rawReference)
    let store = TodoStore()

    if let subtaskId = reference.subtaskId {
        let subtask = try store.toggleSubtaskDone(
            todoId: reference.todoId,
            subtaskId: subtaskId,
            to: isDone
        )
        let verb = isDone ? "Completed" : "Reopened"
        print("\(verb) subtask #\(reference.displayValue): \(subtask.title)")
    } else {
        let todo = try store.toggleDone(id: reference.todoId, to: isDone)
        let verb = isDone ? "Completed" : "Reopened"
        print("\(verb) todo #\(reference.displayValue): \(todo.title)")
    }
}
