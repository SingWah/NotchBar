import AppKit
import Carbon.HIToolbox

/// A system-wide hot key. Carbon is still the only way to register one without
/// asking for Accessibility permission, so the deprecated API is intentional.
enum GlobalHotKey {
    /// ⌃⌥N — used to bring the menu back after the status item is hidden.
    private static let keyCode = UInt32(kVK_ANSI_N)
    private static let modifiers = UInt32(controlKey | optionKey)
    private static let signature: OSType = 0x4E42_4152   // 'NBAR'

    private static var hotKeyRef: EventHotKeyRef?
    private static var handlerRef: EventHandlerRef?
    private static var action: (() -> Void)?

    /// Returns false when the combination is already taken by another app.
    @discardableResult
    static func register(_ action: @escaping () -> Void) -> Bool {
        unregister()
        Self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { GlobalHotKey.action?() }
            return noErr
        }, 1, &eventType, nil, &handlerRef) == noErr

        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let registered = RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                            GetApplicationEventTarget(), 0, &hotKeyRef) == noErr

        guard installed, registered else {
            unregister()
            return false
        }
        return true
    }

    static func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
        hotKeyRef = nil
        handlerRef = nil
        action = nil
    }
}
