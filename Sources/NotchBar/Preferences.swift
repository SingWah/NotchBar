import Foundation

enum Preferences {
    enum Key {
        static let enabled = "enabled"
        static let cornerRadius = "cornerRadius"
        static let showDockIcon = "showDockIcon"
        static let showStatusIcon = "showStatusIcon"
        static let language = "language"
    }

    static let defaultCornerRadius: Double = 22

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Key.enabled: true,
            Key.cornerRadius: defaultCornerRadius,
            Key.showDockIcon: false,
            Key.showStatusIcon: true,
            Key.language: LanguageChoice.system.rawValue
        ])
    }

    /// Menu language; `.system` follows the preferred language of the OS.
    static var language: LanguageChoice {
        get {
            let raw = UserDefaults.standard.string(forKey: Key.language) ?? ""
            return LanguageChoice(rawValue: raw) ?? .system
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.language) }
    }

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Key.enabled) }
        set { UserDefaults.standard.set(newValue, forKey: Key.enabled) }
    }

    /// Radius of the two outward arcs under the bar. 0 means square corners.
    static var cornerRadius: CGFloat {
        get { CGFloat(UserDefaults.standard.double(forKey: Key.cornerRadius)) }
        set { UserDefaults.standard.set(Double(newValue), forKey: Key.cornerRadius) }
    }

    static var showDockIcon: Bool {
        get { UserDefaults.standard.bool(forKey: Key.showDockIcon) }
        set { UserDefaults.standard.set(newValue, forKey: Key.showDockIcon) }
    }

    /// Whether the status item is drawn in the menu bar. Hiding it also turns on
    /// the global hot key, otherwise the menu would be unreachable.
    static var showStatusIcon: Bool {
        get { UserDefaults.standard.bool(forKey: Key.showStatusIcon) }
        set { UserDefaults.standard.set(newValue, forKey: Key.showStatusIcon) }
    }

    static let cornerRadiusPresets: [CGFloat] = [0, 12, 18, 22, 26, 32]
}
