import AppKit
import TBarCore

@MainActor
final class PreferencesWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let config: TBarConfig
    private var prefs: TBarPreferences
    private var onSave: (() -> Void)?

    private var highField: NSTextField!
    private var mediumField: NSTextField!
    private var lowField: NSTextField!
    private var presetButtons: [NSButton] = []

    init(config: TBarConfig, onSave: @escaping () -> Void) {
        self.config = config
        self.prefs = TBarPreferences.load(from: config.directoryURL)
        self.onSave = onSave
    }

    func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "TBar Settings"
        w.center()
        w.delegate = self
        w.isReleasedWhenClosed = false

        let content = NSView(frame: w.contentRect(forFrameRect: w.frame))
        w.contentView = content

        var y: CGFloat = 300

        // Title
        let title = makeLabel("Priority Icons", bold: true)
        title.frame.origin = NSPoint(x: 20, y: y)
        content.addSubview(title)
        y -= 10

        // Presets
        for (index, preset) in PriorityIcons.presets.enumerated() {
            y -= 30
            let preview = "\(preset.icons.high) High  \(preset.icons.medium) Medium  \(preset.icons.low) Low"
            let btn = NSButton(radioButtonWithTitle: "\(preset.name):  \(preview)", target: self, action: #selector(presetSelected(_:)))
            btn.tag = index
            btn.frame = NSRect(x: 20, y: y, width: 320, height: 20)
            btn.state = (prefs.priorityIcons == preset.icons) ? .on : .off
            content.addSubview(btn)
            presetButtons.append(btn)
        }

        // Custom option
        y -= 30
        let customBtn = NSButton(radioButtonWithTitle: "Custom", target: self, action: #selector(presetSelected(_:)))
        customBtn.tag = PriorityIcons.presets.count
        customBtn.frame = NSRect(x: 20, y: y, width: 320, height: 20)
        let isCustom = !PriorityIcons.presets.contains(where: { $0.icons == prefs.priorityIcons })
        customBtn.state = isCustom ? .on : .off
        content.addSubview(customBtn)
        presetButtons.append(customBtn)

        // Custom fields
        y -= 30
        let labels = ["High:", "Medium:", "Low:"]
        let values = [prefs.priorityIcons.high, prefs.priorityIcons.medium, prefs.priorityIcons.low]
        var fields: [NSTextField] = []

        for i in 0..<3 {
            let lbl = makeLabel(labels[i], bold: false)
            lbl.frame = NSRect(x: 40, y: y, width: 60, height: 20)
            content.addSubview(lbl)

            let field = NSTextField(frame: NSRect(x: 110, y: y, width: 60, height: 24))
            field.stringValue = values[i]
            field.alignment = .center
            field.isEnabled = isCustom
            content.addSubview(field)
            fields.append(field)
            y -= 30
        }

        highField = fields[0]
        mediumField = fields[1]
        lowField = fields[2]

        // Buttons
        y -= 10
        let saveBtn = NSButton(title: "Save", target: self, action: #selector(saveClicked))
        saveBtn.frame = NSRect(x: 250, y: y, width: 80, height: 30)
        saveBtn.bezelStyle = .rounded
        saveBtn.keyEquivalent = "\r"
        content.addSubview(saveBtn)

        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancelBtn.frame = NSRect(x: 160, y: y, width: 80, height: 30)
        cancelBtn.bezelStyle = .rounded
        cancelBtn.keyEquivalent = "\u{1b}"
        content.addSubview(cancelBtn)

        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    @objc private func presetSelected(_ sender: NSButton) {
        for btn in presetButtons { btn.state = .off }
        sender.state = .on

        let isCustom = sender.tag == PriorityIcons.presets.count
        highField.isEnabled = isCustom
        mediumField.isEnabled = isCustom
        lowField.isEnabled = isCustom

        if !isCustom {
            let icons = PriorityIcons.presets[sender.tag].icons
            highField.stringValue = icons.high
            mediumField.stringValue = icons.medium
            lowField.stringValue = icons.low
        }
    }

    @objc private func saveClicked() {
        prefs.priorityIcons = PriorityIcons(
            high: highField.stringValue,
            medium: mediumField.stringValue,
            low: lowField.stringValue
        )
        try? prefs.save(to: config.directoryURL)
        window?.close()
        onSave?()
    }

    @objc private func cancelClicked() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }

    private func makeLabel(_ text: String, bold: Bool) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13)
        label.sizeToFit()
        return label
    }
}
