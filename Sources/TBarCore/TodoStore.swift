import Darwin
import Foundation

/// JSON-backed persistence for todos and subtasks.
public final class TodoStore {
    public let config: TBarConfig

    /// Creates a store bound to the provided file-system configuration.
    public init(config: TBarConfig = TBarConfig()) {
        self.config = config
    }

    /// Loads the complete persisted payload.
    public func loadAll() throws -> TodoData {
        try withStoreLock {
            try ensureStoreFileExists()
            return try readData()
        }
    }

    /// Replaces the persisted payload.
    public func save(_ data: TodoData) throws {
        try withStoreLock {
            try ensureStoreFileExists()
            var normalized = data
            normalized.version = TodoData.currentVersion
            try writeData(normalized)
        }
    }

    /// Adds a top-level todo and persists it.
    @discardableResult
    public func addTodo(title: String, priority: Priority = .medium) throws -> Todo {
        try mutateData { data in
            let todo = Todo(
                id: data.nextId,
                title: title,
                priority: priority
            )
            data.todos.append(todo)
            data.nextId += 1
            return todo
        }
    }

    /// Adds a subtask to the specified todo and persists it.
    @discardableResult
    public func addSubtask(title: String, toTodoID todoID: Int) throws -> SubTask {
        try mutateData { data in
            guard let todoIndex = data.todos.firstIndex(where: { $0.id == todoID }) else {
                throw TodoStoreError.todoNotFound(id: todoID)
            }

            let subtask = SubTask(
                id: data.todos[todoIndex].nextSubtaskId,
                title: title
            )
            data.todos[todoIndex].subtasks.append(subtask)
            data.todos[todoIndex].nextSubtaskId += 1
            return subtask
        }
    }

    /// Toggles or explicitly sets the done state for a top-level todo.
    @discardableResult
    public func toggleDone(id: Int, to isDone: Bool? = nil) throws -> Todo {
        try mutateData { data in
            guard let todoIndex = data.todos.firstIndex(where: { $0.id == id }) else {
                throw TodoStoreError.todoNotFound(id: id)
            }

            let newDone = isDone ?? !data.todos[todoIndex].done
            data.todos[todoIndex].done = newDone
            data.todos[todoIndex].completedAt = newDone ? Date() : nil
            return data.todos[todoIndex]
        }
    }

    /// Toggles or explicitly sets the done state for a subtask.
    @discardableResult
    public func toggleSubtaskDone(
        todoId: Int,
        subtaskId: Int,
        to isDone: Bool? = nil
    ) throws -> SubTask {
        try mutateData { data in
            guard let todoIndex = data.todos.firstIndex(where: { $0.id == todoId }) else {
                throw TodoStoreError.todoNotFound(id: todoId)
            }
            guard let subtaskIndex = data.todos[todoIndex].subtasks.firstIndex(where: { $0.id == subtaskId }) else {
                throw TodoStoreError.subtaskNotFound(todoId: todoId, subtaskId: subtaskId)
            }

            data.todos[todoIndex].subtasks[subtaskIndex].done =
                isDone ?? !data.todos[todoIndex].subtasks[subtaskIndex].done
            return data.todos[todoIndex].subtasks[subtaskIndex]
        }
    }

    /// Deletes the specified top-level todo.
    @discardableResult
    public func deleteTodo(id: Int) throws -> Todo {
        try mutateData { data in
            guard let todoIndex = data.todos.firstIndex(where: { $0.id == id }) else {
                throw TodoStoreError.todoNotFound(id: id)
            }

            return data.todos.remove(at: todoIndex)
        }
    }

    /// Deletes the specified subtask.
    @discardableResult
    public func deleteSubtask(todoId: Int, subtaskId: Int) throws -> SubTask {
        try mutateData { data in
            guard let todoIndex = data.todos.firstIndex(where: { $0.id == todoId }) else {
                throw TodoStoreError.todoNotFound(id: todoId)
            }
            guard let subtaskIndex = data.todos[todoIndex].subtasks.firstIndex(where: { $0.id == subtaskId }) else {
                throw TodoStoreError.subtaskNotFound(todoId: todoId, subtaskId: subtaskId)
            }

            return data.todos[todoIndex].subtasks.remove(at: subtaskIndex)
        }
    }

    /// Changes the priority of a top-level todo.
    @discardableResult
    public func setPriority(id: Int, priority: Priority) throws -> Todo {
        try mutateData { data in
            guard let todoIndex = data.todos.firstIndex(where: { $0.id == id }) else {
                throw TodoStoreError.todoNotFound(id: id)
            }

            data.todos[todoIndex].priority = priority
            return data.todos[todoIndex]
        }
    }

    /// Returns todos whose title or subtask titles contain the provided keyword.
    public func search(_ keyword: String) throws -> [Todo] {
        let normalized = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return try loadAll().todos
        }

        return try loadAll().todos.filter { todo in
            todo.title.localizedCaseInsensitiveContains(normalized) ||
                todo.subtasks.contains(where: { $0.title.localizedCaseInsensitiveContains(normalized) })
        }
    }

    private func mutateData<T>(_ mutation: (inout TodoData) throws -> T) throws -> T {
        try withStoreLock {
            try ensureStoreFileExists()
            var data = try readData()
            let result = try mutation(&data)
            data.version = TodoData.currentVersion
            try writeData(data)
            return result
        }
    }

    private func withStoreLock<T>(_ body: () throws -> T) throws -> T {
        try config.ensureDirectoryExists()
        let lockDescriptor = try openFileDescriptor(
            for: config.lockFileURL,
            flags: O_CREAT | O_RDWR
        )
        defer {
            Darwin.close(lockDescriptor)
        }

        if flock(lockDescriptor, LOCK_EX | LOCK_NB) != 0 {
            if errno == EWOULDBLOCK {
                throw TodoStoreError.fileLocked
            }
            throw posixError()
        }
        defer {
            _ = flock(lockDescriptor, LOCK_UN)
        }

        return try body()
    }

    private func ensureStoreFileExists() throws {
        guard !FileManager.default.fileExists(atPath: config.storeFileURL.path) else {
            return
        }

        try writeData(TodoData())
    }

    private func readData() throws -> TodoData {
        let data = try Data(contentsOf: config.storeFileURL)
        guard !data.isEmpty else {
            throw TodoStoreError.corruptedData
        }

        do {
            let decoded = try Self.decoder.decode(TodoData.self, from: data)
            guard decoded.version == TodoData.currentVersion else {
                throw TodoStoreError.corruptedData
            }
            return decoded
        } catch let error as TodoStoreError {
            throw error
        } catch {
            throw TodoStoreError.corruptedData
        }
    }

    private func writeData(_ data: TodoData) throws {
        let encoded = try Self.encoder.encode(data)
        let tempURL = config.directoryURL.appendingPathComponent(
            ".\(config.storeFileURL.lastPathComponent).tmp.\(UUID().uuidString)",
            isDirectory: false
        )
        var renamed = false

        defer {
            if !renamed {
                try? FileManager.default.removeItem(at: tempURL)
            }
        }

        let descriptor = try openFileDescriptor(
            for: tempURL,
            flags: O_CREAT | O_WRONLY | O_TRUNC,
            permissions: 0o600
        )
        defer {
            Darwin.close(descriptor)
        }

        try encoded.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return
            }

            var bytesWritten = 0
            while bytesWritten < buffer.count {
                let result = Darwin.write(
                    descriptor,
                    baseAddress.advanced(by: bytesWritten),
                    buffer.count - bytesWritten
                )
                if result < 0 {
                    throw posixError()
                }
                bytesWritten += result
            }
        }

        if Darwin.fsync(descriptor) != 0 {
            throw posixError()
        }

        try renameItem(at: tempURL, to: config.storeFileURL)
        renamed = true
    }

    private func renameItem(at sourceURL: URL, to destinationURL: URL) throws {
        let result: Int32 = sourceURL.withUnsafeFileSystemRepresentation { sourcePath in
            destinationURL.withUnsafeFileSystemRepresentation { destinationPath in
                guard let sourcePath, let destinationPath else {
                    errno = EINVAL
                    return Int32(-1)
                }
                return Darwin.rename(sourcePath, destinationPath)
            }
        }

        if result != 0 {
            throw posixError()
        }
    }

    private func openFileDescriptor(
        for url: URL,
        flags: Int32,
        permissions: mode_t = 0o600
    ) throws -> Int32 {
        let descriptor = url.withUnsafeFileSystemRepresentation { path -> Int32 in
            guard let path else {
                errno = EINVAL
                return -1
            }
            return Darwin.open(path, flags, permissions)
        }

        guard descriptor >= 0 else {
            throw posixError()
        }
        return descriptor
    }

    private func posixError() -> Error {
        let code = POSIXErrorCode(rawValue: errno) ?? .EIO
        return POSIXError(code)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
