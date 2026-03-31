import AppKit

@main
struct TBarApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let appDelegate = AppDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = appDelegate
        withExtendedLifetime(appDelegate) {
            NSApp.run()
        }
    }
}
