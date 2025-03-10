enum Platform {
    case macOS
    case windows
    
    static var current: Platform {
        #if os(macOS)
        return .macOS
        #elseif os(Windows)
        return .windows
        #else
        fatalError("Unsupported platform")
        #endif
    }
    
    var defaultModifiers: UInt {
        switch self {
        case .macOS:
            return NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue
        case .windows:
            return NSEvent.ModifierFlags.control.rawValue | NSEvent.ModifierFlags.option.rawValue
        }
    }
    
    var defaultModifierDescription: String {
        switch self {
        case .macOS:
            return "⌘⌥"
        case .windows:
            return "Ctrl+Alt"
        }
    }
}