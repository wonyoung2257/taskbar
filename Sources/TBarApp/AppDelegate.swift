import AppKit
import TBarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var menuBuilder: MenuBuilder?
    private var fileWatcher: FileWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = TodoStore()
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "checklist",
                accessibilityDescription: "TBar"
            )
            button.title = " 0"
            button.imagePosition = .imageLeading
        }

        let menuBuilder = MenuBuilder(store: store, statusItem: statusItem)
        statusItem.menu = menuBuilder.menu
        menuBuilder.rebuild()

        let fileWatcher = FileWatcher(config: store.config) { [weak menuBuilder] in
            menuBuilder?.rebuild()
        }
        fileWatcher.start()

        self.statusItem = statusItem
        self.menuBuilder = menuBuilder
        self.fileWatcher = fileWatcher
    }

    func applicationWillTerminate(_ notification: Notification) {
        fileWatcher?.stop()
    }
}
