import Foundation
import TBarCore

struct SearchCommand {
    let keyword: String

    init(arguments: [String]) throws {
        let keyword = arguments.joined(separator: " ").trimmed
        guard !keyword.isEmpty else {
            throw ValidationError("Keyword must not be empty.")
        }
        self.keyword = keyword
    }

    func run() throws {
        let store = TodoStore()
        let todos = try store.search(keyword)

        guard !todos.isEmpty else {
            print("No matching todos found.")
            return
        }

        print(TBarFormatter.renderTodos(todos))
    }
}
