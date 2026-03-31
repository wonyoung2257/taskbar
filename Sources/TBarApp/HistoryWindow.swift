import AppKit
import TBarCore

@MainActor
final class HistoryWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let store: TodoStore
    private let icons: PriorityIcons

    init(store: TodoStore) {
        self.store = store
        self.icons = TBarPreferences.load(from: store.config.directoryURL).priorityIcons
    }

    func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = "TBar History"
        w.center()
        w.delegate = self
        w.isReleasedWhenClosed = false
        w.minSize = NSSize(width: 300, height: 300)

        let scrollView = NSScrollView(frame: w.contentRect(forFrameRect: w.frame))
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]

        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.backgroundColor = .textBackgroundColor
        textView.textColor = .textColor

        let content = buildHistoryContent()
        textView.string = content

        scrollView.documentView = textView
        w.contentView = scrollView

        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    private func buildHistoryContent() -> String {
        guard let data = try? store.loadAll() else {
            return "Failed to load todos."
        }

        let completedTodos = data.todos.filter { $0.done && $0.completedAt != nil }

        guard !completedTodos.isEmpty else {
            return "No completed todos yet."
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let calendar = Calendar.current

        let grouped = Dictionary(grouping: completedTodos) { todo -> String in
            formatter.string(from: todo.completedAt ?? todo.createdAt)
        }

        let today = formatter.string(from: Date())
        let yesterday = formatter.string(from: calendar.date(byAdding: .day, value: -1, to: Date())!)

        let sortedDates = grouped.keys.sorted(by: >)
        var lines: [String] = []

        for dateStr in sortedDates {
            let label: String
            if dateStr == today {
                label = "\(dateStr) (오늘)"
            } else if dateStr == yesterday {
                label = "\(dateStr) (어제)"
            } else {
                label = dateStr
            }

            let todos = grouped[dateStr]!.sorted {
                ($0.completedAt ?? $0.createdAt) < ($1.completedAt ?? $1.createdAt)
            }

            lines.append("── \(label) (\(todos.count)개 완료) ──")
            for todo in todos {
                let progress = todo.subtasks.isEmpty
                    ? ""
                    : " (\(todo.completedSubtaskCount)/\(todo.subtasks.count))"
                lines.append("  ✅ \(todo.title)\(progress)")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
