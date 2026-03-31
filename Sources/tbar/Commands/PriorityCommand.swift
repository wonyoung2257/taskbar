import TBarCore

struct PriorityCommand {
    let reference: String
    let priority: Priority

    init(arguments: [String]) throws {
        guard arguments.count >= 2 else {
            throw ValidationError("Usage: tbar priority <id> <high|medium|low>")
        }
        try requireNoExtraArguments(Array(arguments.dropFirst(2)), commandName: "priority")
        self.reference = arguments[0]
        self.priority = try parsePriority(arguments[1])
    }

    func run() throws {
        let parsedReference = try TodoReference(reference)
        guard parsedReference.subtaskId == nil else {
            throw ValidationError("Priority can only be changed for top-level todos.")
        }

        let store = TodoStore()
        let todo = try store.setPriority(id: parsedReference.todoId, priority: priority)
        print("Updated todo #\(todo.id) priority to \(todo.priority.rawValue).")
    }
}
