import AppKit

/// Draws the top bar: a full-width strip whose two lower corners flare outward
/// to cover the rounded corner of the window sitting underneath it.
final class NotchBarView: NSView {
    /// The window is wider than the screen so the outermost pixel column of the
    /// screen is fully painted. The path itself stays inside the screen.
    var edgeInset: CGFloat = 0

    var cornerRadius: CGFloat = 0

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds
        guard bounds.width > 2, bounds.height > 2 else { return }

        let left = bounds.minX + edgeInset
        let right = bounds.maxX - edgeInset
        let top = bounds.maxY - edgeInset
        let radius = min(cornerRadius, bounds.height - 2, (right - left) / 2)

        NSColor.black.setFill()

        let path = NSBezierPath()
        path.move(to: NSPoint(x: left, y: top))
        path.line(to: NSPoint(x: right, y: top))
        path.line(to: NSPoint(x: right, y: bounds.minY))

        guard radius > 0.5 else {
            path.line(to: NSPoint(x: left, y: bounds.minY))
            path.close()
            path.fill()
            return
        }

        // Right corner: sweep from the bottom edge up into the flat section.
        path.appendArc(withCenter: NSPoint(x: right - radius, y: bounds.minY),
                       radius: radius, startAngle: 0, endAngle: 90, clockwise: false)
        path.line(to: NSPoint(x: left + radius, y: bounds.minY + radius))
        // Left corner: mirror of the above.
        path.appendArc(withCenter: NSPoint(x: left + radius, y: bounds.minY),
                       radius: radius, startAngle: 90, endAngle: 180, clockwise: false)
        path.close()
        path.fill()
    }
}
