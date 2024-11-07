import Foundation

/// App settings and configuration
struct Settings: Codable {
    var selectedModel: OpenAIModel
    var hasApiKey: Bool
    var enableGlobalHotkey: Bool
    var startAtLogin: Bool
    var windowOpacity: Double
    var requestTimeout: Double

    init(
        selectedModel: OpenAIModel = .gpt4oMini,
        hasApiKey: Bool = false,
        enableGlobalHotkey: Bool = true,
        startAtLogin: Bool = false,
        windowOpacity: Double = 0.95,
        requestTimeout: Double = 30.0
    ) {
        self.selectedModel = selectedModel
        self.hasApiKey = hasApiKey
        self.enableGlobalHotkey = enableGlobalHotkey
        self.startAtLogin = startAtLogin
        self.windowOpacity = windowOpacity
        self.requestTimeout = requestTimeout
    }
}

/// Available OpenAI models
enum OpenAIModel: String, Codable, CaseIterable, Identifiable {
    case gpt4o = "gpt-4o"
    case gpt4oMini = "gpt-4o-mini"
    case o1Mini = "o1-mini"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gpt4o:
            return "GPT-4o"
        case .gpt4oMini:
            return "GPT-4o Mini"
        case .o1Mini:
            return "o1 Mini"
        }
    }

    var description: String {
        switch self {
        case .gpt4o:
            return "Most capable model, best for complex tasks"
        case .gpt4oMini:
            return "Fast and efficient, great for most tasks"
        case .o1Mini:
            return "Advanced reasoning model for complex problems"
        }
    }
}

// MARK: - Settings Storage
extension Settings {
    private static let userDefaults = UserDefaults.standard
    private static let settingsKey = "promptd-mux.Settings"

    /// Load settings from UserDefaults
    static func load() -> Settings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(Settings.self, from: data) else {
            return Settings() // Return default settings
        }
        return settings
    }

    /// Save settings to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            Self.userDefaults.set(data, forKey: Self.settingsKey)
        }
    }
}

// MARK: - Preview Data
#if DEBUG
extension Settings {
    static let preview = Settings(
        selectedModel: .gpt4oMini,
        hasApiKey: true,
        enableGlobalHotkey: true,
        startAtLogin: false,
        windowOpacity: 0.95,
        requestTimeout: 30.0
    )
}
#endif
