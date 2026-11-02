import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = OverlayController()
    private var menuBar: MenuBarController?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()
        applyActivationPolicy()

        menuBar = MenuBarController(overlay: overlay) { [weak self] showDockIcon in
            self?.setDockIconVisible(showDockIcon)
        }

        overlay.sync()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Window list changes are not observable; polling is what keeps the bar
        // correct after the menu bar height changes or a display is plugged in.
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.overlay.sync()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
    }

    /// Reopening the app from Finder or the Dock brings the menu back, but only
    /// when the menu bar icon is hidden — otherwise launching at login would pop
    /// the menu on every boot.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !Preferences.showStatusIcon {
            menuBar?.showMenu()
        }
        return false
    }

    @objc private func screenParametersChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.overlay.relayout()
        }
    }

    private func setDockIconVisible(_ visible: Bool) {
        applyActivationPolicy()
        if visible {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func applyActivationPolicy() {
        NSApp.setActivationPolicy(Preferences.showDockIcon ? .regular : .accessory)
    }
}
