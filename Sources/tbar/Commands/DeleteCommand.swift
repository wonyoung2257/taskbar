
import TBarCore

struct DeleteCommand {
    let reference: String

    init(arguments: [String]) throws {
        guard let reference = arguments.first else {
            throw ValidationError("Missing todo reference.")
        }
        try requireNoExtraArguments(Array(arguments.dropFirst()), commandName: "delete")
        self.reference = reference
    }

    func run() throws {
        let parsedReference = try TodoReference(reference)
        let store = TodoStore()

        if let subtaskId = parsedReference.subtaskId {
            let subtask = try store.deleteSubtask(
                todoId: parsedReference.todoId,
                subtaskId: subtaskId
            )
            print("Deleted subtask #\(parsedReference.displayValue): \(subtask.title)")
        } else {
            let todo = try store.deleteTodo(id: parsedReference.todoId)
            print("Deleted todo #\(parsedReference.displayValue): \(todo.title)")
        }
    }
}
