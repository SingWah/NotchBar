import AppKit
import CoreGraphics

enum ScreenMetrics {
    static var builtInScreen: NSScreen? {
        NSScreen.screens.first {
            $0.localizedName.contains("Built-in") || $0.localizedName.contains("内建")
        }
    }

    static func displayID(of screen: NSScreen) -> CGDirectDisplayID? {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return CGDirectDisplayID(number.uint32Value)
    }

    /// Height of the system menu bar on the given screen.
    ///
    /// Reading the window list is more reliable than `safeAreaInsets.top`, which is the
    /// notch height and can be a few points shorter than the bar itself.
    static func menuBarHeight(for screen: NSScreen) -> CGFloat? {
        guard let windows = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        for window in windows {
            guard window[kCGWindowOwnerName as String] as? String == "Window Server",
                  window[kCGWindowName as String] as? String == "Menubar",
                  window[kCGWindowLayer as String] as? Int == 24 else { continue }

            let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
            guard let width = bounds["Width"], let height = bounds["Height"],
                  abs(width - screen.frame.width) < 2, height > 10, height < 90 else { continue }
            return height
        }
        return nil
    }
}
