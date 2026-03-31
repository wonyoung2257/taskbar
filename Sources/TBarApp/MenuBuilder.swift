import AppKit
import TBarCore

@MainActor
final class MenuBuilder: NSObject {
    let menu = NSMenu()

    private let store: TodoStore
    private weak var statusItem: NSStatusItem?
    private let appVersion: String
    private var icons: PriorityIcons
    private var preferencesWindow: PreferencesWindow?
    private var historyWindow: HistoryWindow?

    private var todoViews: [Int: CheckboxMenuItemView] = [:]

    init(
        store: TodoStore = TodoStore(),
        statusItem: NSStatusItem,
        appVersion: String = "0.1.0"
    ) {
        self.store = store
        self.statusItem = statusItem
        self.appVersion = appVersion
        self.icons = TBarPreferences.load(from: store.config.directoryURL).priorityIcons
    }

    func rebuild() {
        menu.removeAllItems()
        todoViews.removeAll()
        icons = TBarPreferences.load(from: store.config.directoryURL).priorityIcons

        do {
            let todos = try store.loadAll().todos
                .filter { !$0.isCompletedBeforeToday }
                .sorted(by: sortTodos)

            if todos.isEmpty {
                addDisabledItem(title: "No todos")
            } else {
                for todo in todos {
                    addMenuItems(for: todo)
                }
            }

            updateStatusItem(incompleteCount: todos.filter { !$0.done }.count)
        } catch {
            addDisabledItem(title: error.localizedDescription)
            updateStatusItem(incompleteCount: 0)
        }

        menu.addItem(NSMenuItem.separator())

        let historyItem = NSMenuItem(
            title: "History…",
            action: #selector(openHistory),
            keyEquivalent: "h"
        )
        historyItem.target = self
        menu.addItem(historyItem)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        let versionItem = NSMenuItem(title: "tbar v\(appVersion)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
    }

    @objc private func openHistory() {
        if historyWindow == nil {
            historyWindow = HistoryWindow(store: store)
        }
        historyWindow?.show()
    }

    @objc private func openSettings() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow(config: store.config) { [weak self] in
                self?.rebuild()
            }
        }
        preferencesWindow?.show()
    }

    private func addMenuItems(for todo: Todo) {
        menu.addItem(makeTodoItem(for: todo))

        for subtask in todo.subtasks {
            menu.addItem(makeSubtaskItem(todoID: todo.id, subtask: subtask))
        }
    }

    private func makeTodoItem(for todo: Todo) -> NSMenuItem {
        let item = NSMenuItem()
        let view = CheckboxMenuItemView(
            title: title(for: todo),
            isChecked: todo.done
        )
        let todoID = todo.id
        todoViews[todoID] = view
        view.onToggle = { [weak self] in
            guard let self else { return }
            _ = try? self.store.toggleDone(id: todoID)
            self.rebuild()
        }
        item.view = view
        return item
    }

    private func makeSubtaskItem(todoID: Int, subtask: SubTask) -> NSMenuItem {
        let item = NSMenuItem()
        let view = CheckboxMenuItemView(
            title: subtask.title,
            isChecked: subtask.done,
            indentLevel: 1
        )
        let subtaskID = subtask.id
        view.onToggle = { [weak self] in
            guard let self else { return }
            if let updated = try? self.store.toggleSubtaskDone(todoId: todoID, subtaskId: subtaskID) {
                view.setChecked(updated.done)
            }
            self.refreshParentTodo(id: todoID)
            self.refreshStatusCount()
        }
        item.view = view
        return item
    }

    private func refreshParentTodo(id todoID: Int) {
        guard let parentView = todoViews[todoID],
              let data = try? store.loadAll(),
              let todo = data.todos.first(where: { $0.id == todoID }) else { return }
        parentView.setTitle(title(for: todo))
    }

    private func refreshStatusCount() {
        guard let data = try? store.loadAll() else { return }
        updateStatusItem(incompleteCount: data.todos.filter { !$0.done }.count)
    }

    private func title(for todo: Todo) -> String {
        let icon: String
        switch todo.priority {
        case .high:
            icon = icons.high
        case .medium:
            icon = icons.medium
        case .low:
            icon = icons.low
        }

        let progress = todo.subtasks.isEmpty
            ? ""
            : " (\(todo.completedSubtaskCount)/\(todo.subtasks.count))"
        return "[\(icon)] \(todo.title)\(progress)"
    }

    private func sortTodos(lhs: Todo, rhs: Todo) -> Bool {
        if lhs.done != rhs.done {
            return !lhs.done && rhs.done
        }

        if lhs.priority != rhs.priority {
            return lhs.priority < rhs.priority
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        return lhs.id < rhs.id
    }

    private func addDisabledItem(title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func updateStatusItem(incompleteCount: Int) {
        guard let button = statusItem?.button else {
            return
        }

        button.title = " \(incompleteCount)"
        button.toolTip = "\(incompleteCount) incomplete todo\(incompleteCount == 1 ? "" : "s")"
    }
}
