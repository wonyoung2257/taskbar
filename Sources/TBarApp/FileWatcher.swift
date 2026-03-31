import Darwin
import Dispatch
import Foundation
import TBarCore

@MainActor
final class FileWatcher {
    private let config: TBarConfig
    private let onChange: @MainActor () -> Void

    private var source: DispatchSourceFileSystemObject?

    init(
        config: TBarConfig = TBarConfig(),
        onChange: @escaping @MainActor () -> Void
    ) {
        self.config = config
        self.onChange = onChange
    }

    func start() {
        guard source == nil else {
            return
        }

        do {
            try ensureObservedFileExists()
            try connectSource()
        } catch {
            onChange()
        }
    }

    func stop() {
        guard let source else {
            return
        }

        self.source = nil
        source.setEventHandler {}
        source.cancel()
    }

    private func ensureObservedFileExists() throws {
        _ = try TodoStore(config: config).loadAll()
    }

    private func connectSource() throws {
        let descriptor = open(config.storeFileURL.path, O_EVTONLY)
        guard descriptor >= 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self, weak source] in
            guard let self, let source else {
                return
            }

            Task { @MainActor in
                self.handleEvent(source.data)
            }
        }

        source.setCancelHandler {
            Darwin.close(descriptor)
        }

        self.source = source
        source.resume()
    }

    private func handleEvent(_ event: DispatchSource.FileSystemEvent) {
        let shouldReconnect = event.contains(.rename) || event.contains(.delete)
        onChange()

        if shouldReconnect {
            reconnect()
        }
    }

    private func reconnect() {
        stop()

        do {
            try ensureObservedFileExists()
            try connectSource()
        } catch {
            // Leave the watcher stopped if the store is temporarily unavailable.
        }
    }
}
