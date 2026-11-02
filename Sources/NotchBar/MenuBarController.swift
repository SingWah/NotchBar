import AppKit

private enum Author {
    static let name = "SingWah"
    static let url = URL(string: "https://github.com/SingWah")!
}

final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let overlay: OverlayController
    private let onDockIconChange: (Bool) -> Void

    init(overlay: OverlayController, onDockIconChange: @escaping (Bool) -> Void) {
        self.overlay = overlay
        self.onDockIconChange = onDockIconChange
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        statusItem.button?.image = StatusIcon.make()
        statusItem.button?.toolTip = "NotchBar"

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        applyStatusIconVisibility()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let text = Localized.current

        let toggleItem = NSMenuItem(title: text.hideNotch, action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.state = Preferences.isEnabled ? .on : .off
        menu.addItem(toggleItem)

        let radiusItem = NSMenuItem(title: text.cornerRadius, action: nil, keyEquivalent: "")
        let radiusMenu = NSMenu()
        for preset in Preferences.cornerRadiusPresets {
            let title = preset == 0 ? text.squareCorners : "\(Int(preset)) pt"
            let item = NSMenuItem(title: title, action: #selector(selectRadius(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset
            item.state = abs(preset - Preferences.cornerRadius) < 0.5 ? .on : .off
            radiusMenu.addItem(item)
        }
        radiusItem.submenu = radiusMenu
        menu.addItem(radiusItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: text.launchAtLogin, action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(loginItem)

        let statusItemToggle = NSMenuItem(title: text.showStatusIcon,
                                          action: #selector(toggleStatusIcon),
                                          keyEquivalent: "")
        statusItemToggle.target = self
        statusItemToggle.state = Preferences.showStatusIcon ? .on : .off
        menu.addItem(statusItemToggle)

        let dockItem = NSMenuItem(title: text.showDockIcon, action: #selector(toggleDockIcon), keyEquivalent: "")
        dockItem.target = self
        dockItem.state = Preferences.showDockIcon ? .on : .off
        menu.addItem(dockItem)

        menu.addItem(languageMenuItem(text: text))

        menu.addItem(.separator())

        let about = NSMenuItem(title: text.about, action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: text.quit, action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func languageMenuItem(text: Localized) -> NSMenuItem {
        let root = NSMenuItem(title: text.language, action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let choices: [(LanguageChoice, String)] = [
            (.system, text.languageSystem),
            (.chinese, text.languageChinese),
            (.english, text.languageEnglish)
        ]
        for (choice, title) in choices {
            let item = NSMenuItem(title: title, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = choice.rawValue
            item.state = choice == Preferences.language ? .on : .off
            submenu.addItem(item)
        }
        root.submenu = submenu
        return root
    }

    /// Pops the menu under the right end of the menu bar. Used by the global hot
    /// key and when the app is reopened from Finder while its icon is hidden.
    func showMenu() {
        guard let menu = statusItem.menu else { return }
        // An accessory app has to be frontmost before its menu can be tracked.
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        }
        menuNeedsUpdate(menu)
        menu.popUp(positioning: nil, at: anchorPoint(), in: nil)
    }

    /// Where the hidden status item would have been: right of the menu bar.
    private func anchorPoint() -> NSPoint {
        guard let screen = ScreenMetrics.builtInScreen ?? NSScreen.main ?? NSScreen.screens.first else {
            return NSEvent.mouseLocation
        }
        let menuBar = ScreenMetrics.menuBarHeight(for: screen) ?? 24
        let rightEdge = screen.frame.maxX - 220
        return NSPoint(x: max(screen.frame.minX + 8, rightEdge),
                       y: screen.frame.maxY - menuBar - 4)
    }

    @objc private func toggleEnabled() {
        Preferences.isEnabled.toggle()
        overlay.sync()
    }

    @objc private func selectRadius(_ sender: NSMenuItem) {
        guard let preset = sender.representedObject as? CGFloat else { return }
        Preferences.cornerRadius = preset
        overlay.relayout()
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let choice = LanguageChoice(rawValue: raw) else { return }
        Preferences.language = choice
    }

    @objc private func toggleLoginItem() {
        do {
            try LoginItem.setEnabled(!LoginItem.isEnabled)
        } catch {
            presentError(error)
        }
    }

    @objc private func toggleStatusIcon() {
        Preferences.showStatusIcon.toggle()
        // Hiding the item while its own menu is still tracking upsets AppKit, so
        // the change lands once the menu has closed.
        DispatchQueue.main.async {
            self.applyStatusIconVisibility()

            if !Preferences.showStatusIcon {
                self.explainHiddenAccess()
            } else if !self.iconIsHidden {
                // The hot key was taken by another app; the icon stayed.
                self.explainHotKeyTaken()
            }
        }
    }

    private var iconIsHidden: Bool {
        !statusItem.isVisible
    }

    /// The menu lives on the status item, so a hidden icon needs a way back in.
    private func explainHiddenAccess() {
        let text = Localized.current
        let alert = NSAlert()
        alert.messageText = text.hiddenTitle
        alert.informativeText = text.hiddenBody
        alert.addButton(withTitle: text.ok)
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func explainHotKeyTaken() {
        let text = Localized.current
        let alert = NSAlert()
        alert.messageText = text.hotKeyTakenTitle
        alert.informativeText = text.hotKeyTakenBody
        alert.alertStyle = .warning
        alert.addButton(withTitle: text.ok)
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func toggleDockIcon() {
        Preferences.showDockIcon.toggle()
        onDockIconChange(Preferences.showDockIcon)
    }

    @objc private func showAbout() {
        let text = Localized.current
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "NotchBar \(version)"
            alert.informativeText = text.aboutBody
            alert.alertStyle = .informational
            alert.addButton(withTitle: text.ok)
            alert.addButton(withTitle: text.openGitHub)

            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertSecondButtonReturn {
                self.openAuthorPage()
            }
        }
    }

    private func openAuthorPage() {
        NSWorkspace.shared.open(Author.url)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func applyStatusIconVisibility() {
        if Preferences.showStatusIcon {
            GlobalHotKey.unregister()
            statusItem.isVisible = true
            return
        }

        // Without a hot key the menu would be unreachable, so the icon stays.
        guard GlobalHotKey.register({ [weak self] in self?.showMenu() }) else {
            Preferences.showStatusIcon = true
            statusItem.isVisible = true
            return
        }
        statusItem.isVisible = false
    }

    private func presentError(_ error: Error) {
        let text = Localized.current
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = text.errorTitle
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
