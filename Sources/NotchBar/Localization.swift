import Foundation

/// What the user picked in the Language submenu.
enum LanguageChoice: String, CaseIterable {
    case system
    case chinese
    case english
}

/// Every user-facing string. One instance per language, picked at read time so a
/// language change takes effect the next time the menu is opened.
struct Localized {
    let hideNotch: String
    let cornerRadius: String
    let squareCorners: String
    let launchAtLogin: String
    let showStatusIcon: String
    let showDockIcon: String
    let language: String
    let languageSystem: String
    let languageChinese: String
    let languageEnglish: String
    let about: String
    let quit: String
    let aboutBody: String
    let hiddenTitle: String
    let hiddenBody: String
    let hotKeyTakenTitle: String
    let hotKeyTakenBody: String
    let errorTitle: String
    let ok: String
    let openGitHub: String

    static var current: Localized {
        switch Preferences.language {
        case .chinese: return .chinese
        case .english: return .english
        case .system: return systemPrefersChinese ? .chinese : .english
        }
    }

    private static var systemPrefersChinese: Bool {
        (Locale.preferredLanguages.first ?? "en").hasPrefix("zh")
    }

    static let chinese = Localized(
        hideNotch: "隐藏刘海",
        cornerRadius: "圆角",
        squareCorners: "直角",
        launchAtLogin: "开机启动",
        showStatusIcon: "在菜单栏显示图标",
        showDockIcon: "在 Dock 中显示",
        language: "语言",
        languageSystem: "跟随系统",
        languageChinese: "中文",
        languageEnglish: "English",
        about: "关于 NotchBar",
        quit: "退出",
        aboutBody: """
        把菜单栏整条绘制为黑色，让刘海融入其中，同时保留壁纸。

        自适应屏幕分辨率与外接屏；只在带刘海的显示器上生效。

        作者：SingWah
        https://github.com/SingWah
        """,
        hiddenTitle: "菜单栏图标已隐藏",
        hiddenBody: """
        按 ⌃⌥N 可以在任意应用里叫出 NotchBar 菜单。

        也可以从「应用程序」里再次打开 NotchBar，或者在菜单里打开 Dock 图标。
        """,
        hotKeyTakenTitle: "⌃⌥N 已被其他应用占用",
        hotKeyTakenBody: "图标先保持显示，否则就没有入口可以改回来了。关掉占用这个快捷键的应用再试。",
        errorTitle: "操作失败",
        ok: "好",
        openGitHub: "打开 GitHub"
    )

    static let english = Localized(
        hideNotch: "Hide Notch",
        cornerRadius: "Corner Radius",
        squareCorners: "Square",
        launchAtLogin: "Launch at Login",
        showStatusIcon: "Show Menu Bar Icon",
        showDockIcon: "Show in Dock",
        language: "Language",
        languageSystem: "System Default",
        languageChinese: "中文",
        languageEnglish: "English",
        about: "About NotchBar",
        quit: "Quit",
        aboutBody: """
        Paints the whole menu bar black so the notch blends into it. The wallpaper and the display resolution stay untouched.

        Follows every display scale and external monitors; it only shows up on screens with a notch.

        Author: SingWah
        https://github.com/SingWah
        """,
        hiddenTitle: "Menu bar icon hidden",
        hiddenBody: """
        Press ⌃⌥N in any app to bring the NotchBar menu back.

        You can also open NotchBar again from Applications, or turn on the Dock icon from the menu.
        """,
        hotKeyTakenTitle: "⌃⌥N is already in use",
        hotKeyTakenBody: "The icon stays visible, otherwise there would be no way back to these settings. Quit the app that owns this shortcut and try again.",
        errorTitle: "Something went wrong",
        ok: "OK",
        openGitHub: "Open GitHub"
    )
}
