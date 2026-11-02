import AppKit

/// Menu bar glyph: a screen outline with a notch hanging from its top edge.
enum StatusIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            let screen = NSBezierPath(roundedRect: NSRect(x: 1.2, y: 4.2, width: 15.6, height: 9.8),
                                      xRadius: 2.0, yRadius: 2.0)
            screen.lineWidth = 1.4
            NSColor.black.setStroke()
            screen.stroke()

            let notchWidth: CGFloat = 4.4
            let notchDepth: CGFloat = 2.9
            let corner: CGFloat = 1.0
            let top: CGFloat = 13.9
            let left = 9 - notchWidth / 2
            let right = 9 + notchWidth / 2
            let bottom = top - notchDepth

            let notch = NSBezierPath()
            notch.move(to: NSPoint(x: left, y: top))
            notch.line(to: NSPoint(x: left, y: bottom + corner))
            notch.appendArc(withCenter: NSPoint(x: left + corner, y: bottom + corner),
                            radius: corner, startAngle: 180, endAngle: 270, clockwise: false)
            notch.line(to: NSPoint(x: right - corner, y: bottom))
            notch.appendArc(withCenter: NSPoint(x: right - corner, y: bottom + corner),
                            radius: corner, startAngle: 270, endAngle: 360, clockwise: false)
            notch.line(to: NSPoint(x: right, y: top))
            notch.close()
            NSColor.black.setFill()
            notch.fill()

            return true
        }
        image.isTemplate = true
        return image
    }
}
