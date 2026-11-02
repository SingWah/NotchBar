import AppKit

private final class BarWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // Default implementation keeps windows inside visibleFrame, which would push
    // the bar below the menu bar and expose the notch.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

final class OverlayController {
    private var window: BarWindow?
    private var isVisible = false

    /// Extra height so a window's own top-edge antialiasing row is covered.
    private let bottomOverlap: CGFloat = 1
    /// The window extends past the screen so its outermost column is fully painted.
    private let edgeOutset: CGFloat = 1

    func relayout() {
        rebuild()
    }

    /// Keeps the overlay in sync with the current display configuration and settings.
    func sync() {
        guard let screen = ScreenMetrics.builtInScreen else {
            remove()
            return
        }

        guard shouldShow(on: screen) else {
            remove()
            return
        }

        let expected = frame(for: screen)
        if let window = window {
            if differs(window.frame, expected) {
                rebuild()
            } else if !isVisible {
                window.orderFrontRegardless()
                isVisible = true
            }
        } else {
            rebuild()
        }
    }

    private func shouldShow(on screen: NSScreen) -> Bool {
        // A screen without a notch already has a black area above the menu bar.
        Preferences.isEnabled && screen.safeAreaInsets.top > 0
    }

    private func frame(for screen: NSScreen) -> NSRect {
        let menuBar = ScreenMetrics.menuBarHeight(for: screen) ?? (screen.safeAreaInsets.top + 1)
        let height = menuBar + bottomOverlap + Preferences.cornerRadius
        return NSRect(x: screen.frame.minX - edgeOutset,
                      y: screen.frame.maxY - height,
                      width: screen.frame.width + edgeOutset * 2,
                      height: height + edgeOutset)
    }

    private func differs(_ a: NSRect, _ b: NSRect) -> Bool {
        abs(a.width - b.width) > 0.5 || abs(a.height - b.height) > 0.5 || abs(a.maxY - b.maxY) > 0.5
    }

    private func rebuild() {
        window?.orderOut(nil)
        window = nil
        isVisible = false

        guard let screen = ScreenMetrics.builtInScreen, shouldShow(on: screen) else { return }

        let rect = frame(for: screen)
        let window = BarWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.alphaValue = 1
        window.level = NSWindow.Level(rawValue: 23)   // just below the menu bar window (24)
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false

        let view = NotchBarView(frame: NSRect(origin: .zero, size: rect.size))
        view.edgeInset = edgeOutset
        view.cornerRadius = Preferences.cornerRadius
        window.contentView = view

        window.orderFrontRegardless()

        self.window = window
        isVisible = true
    }

    private func remove() {
        guard window != nil else { return }
        window?.orderOut(nil)
        window = nil
        isVisible = false
    }
}
