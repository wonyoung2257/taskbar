import Foundation

/// File-system configuration for the shared todo store.
public struct TBarConfig: Sendable {
    public let directoryURL: URL
    public let storeFileURL: URL
    public let lockFileURL: URL

    /// Creates a configuration rooted in the provided home directory.
    public init(
        homeDirectoryURL: URL = URL(
            fileURLWithPath: ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory(),
            isDirectory: true
        ),
        directoryName: String = ".tbar",
        fileName: String = "todos.json"
    ) {
        let directoryURL = homeDirectoryURL.appendingPathComponent(directoryName, isDirectory: true)
        self.directoryURL = directoryURL
        self.storeFileURL = directoryURL.appendingPathComponent(fileName, isDirectory: false)
        self.lockFileURL = directoryURL.appendingPathComponent("\(fileName).lock", isDirectory: false)
    }

    /// Ensures the backing directory exists before any store access.
    public func ensureDirectoryExists(fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
