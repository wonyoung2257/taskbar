import Foundation
import XCTest
@testable import TBarCore

final class TodoStoreTests: XCTestCase {
    func testLoadAllCreatesBackingDirectoryAndFile() throws {
        let context = try TestContext()
        let data = try context.store.loadAll()

        XCTAssertEqual(data, TodoData())
        XCTAssertTrue(FileManager.default.fileExists(atPath: context.config.directoryURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: context.config.storeFileURL.path))
    }

    func testSaveAndLoadRoundTrip() throws {
        let context = try TestContext()
        let createdAt = ISO8601DateFormatter().date(from: "2026-03-29T10:00:00Z") ?? Date()
        let payload = TodoData(
            todos: [
                Todo(
                    id: 1,
                    title: "API design",
                    priority: .high,
                    done: false,
                    createdAt: createdAt,
                    nextSubtaskId: 2,
                    subtasks: [
                        SubTask(id: 1, title: "Define endpoints", done: true)
                    ]
                )
            ],
            nextId: 2
        )

        try context.store.save(payload)
        let reloaded = try context.store.loadAll()

        XCTAssertEqual(reloaded, payload)
    }

    func testAddTodoAssignsIncrementingIDsAndPersistsValues() throws {
        let context = try TestContext()

        let first = try context.store.addTodo(title: "First task", priority: .high)
        let second = try context.store.addTodo(title: "Second task")
        let data = try context.store.loadAll()

        XCTAssertEqual(first.id, 1)
        XCTAssertEqual(second.id, 2)
        XCTAssertEqual(data.nextId, 3)
        XCTAssertEqual(data.todos.map(\.title), ["First task", "Second task"])
        XCTAssertEqual(data.todos.map(\.priority), [.high, .medium])
    }

    func testAddSubtaskAppendsSubtasksAndIncrementsPerTodoCounter() throws {
        let context = try TestContext()
        _ = try context.store.addTodo(title: "Parent task")

        let first = try context.store.addSubtask(title: "Subtask A", toTodoID: 1)
        let second = try context.store.addSubtask(title: "Subtask B", toTodoID: 1)
        let data = try context.store.loadAll()

        XCTAssertEqual(first.id, 1)
        XCTAssertEqual(second.id, 2)
        XCTAssertEqual(data.todos.first?.nextSubtaskId, 3)
        XCTAssertEqual(data.todos.first?.subtasks.map(\.title), ["Subtask A", "Subtask B"])
    }

    func testToggleDoneCanSetDoneAndUndoneState() throws {
        let context = try TestContext()
        _ = try context.store.addTodo(title: "Ship CLI")

        let completed = try context.store.toggleDone(id: 1, to: true)
        let reopened = try context.store.toggleDone(id: 1, to: false)

        XCTAssertTrue(completed.done)
        XCTAssertFalse(reopened.done)
    }

    func testToggleSubtaskDoneUpdatesNestedSubtasks() throws {
        let context = try TestContext()
        _ = try context.store.addTodo(title: "Ship CLI")
        _ = try context.store.addSubtask(title: "Wire parser", toTodoID: 1)

        let completed = try context.store.toggleSubtaskDone(todoId: 1, subtaskId: 1, to: true)
        let reopened = try context.store.toggleSubtaskDone(todoId: 1, subtaskId: 1, to: false)

        XCTAssertTrue(completed.done)
        XCTAssertFalse(reopened.done)
    }

    func testDeleteTodoRemovesTopLevelTodo() throws {
        let context = try TestContext()
        _ = try context.store.addTodo(title: "One")
        _ = try context.store.addTodo(title: "Two")

        let deleted = try context.store.deleteTodo(id: 1)
        let remaining = try context.store.loadAll().todos

        XCTAssertEqual(deleted.title, "One")
        XCTAssertEqual(remaining.map(\.id), [2])
    }

    func testDeleteSubtaskRemovesOnlyTargetedSubtask() throws {
        let context = try TestContext()
        _ = try context.store.addTodo(title: "One")
        _ = try context.store.addSubtask(title: "A", toTodoID: 1)
        _ = try context.store.addSubtask(title: "B", toTodoID: 1)

        let deleted = try context.store.deleteSubtask(todoId: 1, subtaskId: 1)
        let remaining = try context.store.loadAll().todos[0].subtasks

        XCTAssertEqual(deleted.title, "A")
        XCTAssertEqual(remaining.map(\.id), [2])
        XCTAssertEqual(remaining.map(\.title), ["B"])
    }

    func testSetPriorityUpdatesTodoPriority() throws {
        let context = try TestContext()
        _ = try context.store.addTodo(title: "Review API")

        let updated = try context.store.setPriority(id: 1, priority: .low)
        let stored = try context.store.loadAll().todos[0]

        XCTAssertEqual(updated.priority, .low)
        XCTAssertEqual(stored.priority, .low)
    }

    func testSearchMatchesTodoAndSubtaskTitlesCaseInsensitively() throws {
        let context = try TestContext()
        _ = try context.store.addTodo(title: "Write release notes")
        _ = try context.store.addTodo(title: "Backend work")
        _ = try context.store.addSubtask(title: "Draft RELEASE mail", toTodoID: 2)

        let todoMatches = try context.store.search("release")
        let subtaskMatches = try context.store.search("mail")

        XCTAssertEqual(todoMatches.map(\.id), [1, 2])
        XCTAssertEqual(subtaskMatches.map(\.id), [2])
    }

    func testMissingTodoOperationsThrowTodoNotFound() throws {
        let context = try TestContext()

        XCTAssertThrowsError(try context.store.addSubtask(title: "Ghost", toTodoID: 99)) {
            XCTAssertEqual($0 as? TodoStoreError, .todoNotFound(id: 99))
        }
        XCTAssertThrowsError(try context.store.toggleDone(id: 99, to: true)) {
            XCTAssertEqual($0 as? TodoStoreError, .todoNotFound(id: 99))
        }
        XCTAssertThrowsError(try context.store.deleteTodo(id: 99)) {
            XCTAssertEqual($0 as? TodoStoreError, .todoNotFound(id: 99))
        }
        XCTAssertThrowsError(try context.store.setPriority(id: 99, priority: .high)) {
            XCTAssertEqual($0 as? TodoStoreError, .todoNotFound(id: 99))
        }
    }

    func testMissingSubtaskOperationsThrowSubtaskNotFound() throws {
        let context = try TestContext()
        _ = try context.store.addTodo(title: "Parent")

        XCTAssertThrowsError(try context.store.toggleSubtaskDone(todoId: 1, subtaskId: 9, to: true)) {
            XCTAssertEqual($0 as? TodoStoreError, .subtaskNotFound(todoId: 1, subtaskId: 9))
        }
        XCTAssertThrowsError(try context.store.deleteSubtask(todoId: 1, subtaskId: 9)) {
            XCTAssertEqual($0 as? TodoStoreError, .subtaskNotFound(todoId: 1, subtaskId: 9))
        }
    }

    func testInvalidJSONIsReportedAsCorruptedData() throws {
        let context = try TestContext()
        try context.config.ensureDirectoryExists()
        try Data("not json".utf8).write(to: context.config.storeFileURL)

        XCTAssertThrowsError(try context.store.loadAll()) {
            XCTAssertEqual($0 as? TodoStoreError, .corruptedData)
        }
    }
}

private final class TestContext {
    let rootURL: URL
    let config: TBarConfig
    let store: TodoStore

    init() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        config = TBarConfig(homeDirectoryURL: rootURL, directoryName: ".tbar-tests")
        store = TodoStore(config: config)
    }

    deinit {
        try? FileManager.default.removeItem(at: rootURL)
    }
}
