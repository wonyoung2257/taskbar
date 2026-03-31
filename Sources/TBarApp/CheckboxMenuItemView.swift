import AppKit

@MainActor
final class CheckboxMenuItemView: NSView {
    private let checkbox: NSButton
    private var isHighlighted = false
    var onToggle: (() -> Void)?

    init(title: String, isChecked: Bool, indentLevel: Int = 0) {
        checkbox = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        checkbox.state = isChecked ? .on : .off
        checkbox.font = .menuFont(ofSize: 14)
        checkbox.isBordered = false
        checkbox.sizeToFit()

        let leading = CGFloat(20 + indentLevel * 20)
        let width = max(leading + checkbox.frame.width + 16, 250)
        let height: CGFloat = 22

        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))

        checkbox.target = self
        checkbox.action = #selector(checkboxClicked)
        checkbox.frame.origin = NSPoint(x: leading, y: (height - checkbox.frame.height) / 2)
        addSubview(checkbox)

        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func setChecked(_ checked: Bool) {
        checkbox.state = checked ? .on : .off
    }

    func setTitle(_ newTitle: String) {
        checkbox.title = newTitle
        checkbox.sizeToFit()
        let width = max(checkbox.frame.origin.x + checkbox.frame.width + 16, 250)
        frame.size.width = width
    }

    @objc private func checkboxClicked() {
        onToggle?()
    }

    override func mouseEntered(with event: NSEvent) {
        isHighlighted = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHighlighted = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        if isHighlighted {
            NSColor.controlAccentColor.withAlphaComponent(0.2).setFill()
            bounds.fill()
        }
        super.draw(dirtyRect)
    }
}
