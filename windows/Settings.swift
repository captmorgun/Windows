import Carbon.HIToolbox
import ServiceManagement
import SwiftUI

enum ModifierKey: String, CaseIterable, Identifiable {
    case option = "Option"
    case command = "Command"
    case control = "Control"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .option: return "⌥"
        case .command: return "⌘"
        case .control: return "⌃"
        }
    }

    var cgEventFlag: CGEventFlags {
        switch self {
        case .option: return .maskAlternate
        case .command: return .maskCommand
        case .control: return .maskControl
        }
    }
}

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var modifierKey: ModifierKey {
        didSet { UserDefaults.standard.set(modifierKey.rawValue, forKey: "modifierKey") }
    }

    var leftWidthPercent: Double {
        didSet { UserDefaults.standard.set(leftWidthPercent, forKey: "leftWidthPercent") }
    }

    var topHeightPercent: Double {
        didSet { UserDefaults.standard.set(topHeightPercent, forKey: "topHeightPercent") }
    }

    var rightWidthPercent: Double { 100 - leftWidthPercent }
    var bottomHeightPercent: Double { 100 - topHeightPercent }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        }
    }

    private init() {
        let defaults = UserDefaults.standard

        if let raw = defaults.string(forKey: "modifierKey"),
            let key = ModifierKey(rawValue: raw)
        {
            modifierKey = key
        } else {
            modifierKey = .option
        }

        let savedLeft = defaults.double(forKey: "leftWidthPercent")
        leftWidthPercent = savedLeft > 0 ? savedLeft : 50

        let savedTop = defaults.double(forKey: "topHeightPercent")
        topHeightPercent = savedTop > 0 ? savedTop : 50
    }
}
