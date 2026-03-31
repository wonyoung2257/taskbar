import Foundation

/// Errors surfaced by `TodoStore` for expected user-facing failures.
public enum TodoStoreError: Error, Equatable {
    case todoNotFound(id: Int)
    case subtaskNotFound(todoId: Int, subtaskId: Int)
    case corruptedData
    case fileLocked
}

extension TodoStoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .todoNotFound(id):
            return "Todo #\(id) was not found."
        case let .subtaskNotFound(todoId, subtaskId):
            return "Subtask #\(todoId).\(subtaskId) was not found."
        case .corruptedData:
            return "The todo data file is corrupted."
        case .fileLocked:
            return "The todo data file is currently locked by another process."
        }
    }
}
