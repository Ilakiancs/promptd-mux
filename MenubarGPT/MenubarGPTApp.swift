import SwiftUI

/// Main app structure for MenubarGPT
@main
struct MenubarGPTApp: App {
    @StateObject private var historyStore = HistoryStore.shared
    @StateObject private var openAIClient = OpenAIClient()
    @State private var settings = Settings.load()
    
    var body: some Scene {
        MenuBarExtra("MenubarGPT", systemImage: "message.badge") {
            MenubarGPTView()
                .environmentObject(historyStore)
                .environmentObject(openAIClient)
                .environment(\.settings, settings)
                .onReceive(NotificationCenter.default.publisher(for: .settingsDidChange)) { _ in
                    settings = Settings.load()
                }
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentSize)
        
        // Settings window (hidden by default, can be shown via menu)
        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(openAIClient)
                .environment(\.settings, settings)
                .frame(width: 500, height: 400)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
    
    init() {
        // Setup will be done in onAppear
    }
}

/// Main view displayed in the menubar popup
struct MenubarGPTView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var openAIClient: OpenAIClient
    @Environment(\.settings) private var settings
    @Environment(\.openURL) private var openURL
    
    @State private var showingSettings = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and buttons
            headerView
            
            Divider()
            
            // Main chat interface
            ChatView()
                .environmentObject(historyStore)
                .environmentObject(openAIClient)
                .frame(width: 420, height: 480) // Reduced height to account for header
        }
        .frame(width: 420, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Ensure app doesn't show in dock
            DispatchQueue.main.async {
                NSApplication.shared.setActivationPolicy(.accessory)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            showingSettings = true
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // App icon and title
            HStack(spacing: 8) {
                Image(systemName: "message.badge.filled.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("MenubarGPT")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Open web ChatGPT button
                Button(action: openWebChatGPT) {
                    Image(systemName: "safari")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Open ChatGPT in Browser")
                
                // Settings button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
                
                // Quit button
                Button(action: quitApp) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit MenubarGPT")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(openAIClient)
                .environment(\.settings, settings)
                .frame(width: 500, height: 400)
        }
    }
    
    private func openWebChatGPT() {
        guard let url = URL(string: "https://chat.openai.com") else { return }
        openURL(url)
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Settings Environment Key

private struct SettingsKey: EnvironmentKey {
    static let defaultValue = Settings()
}

extension EnvironmentValues {
    var settings: Settings {
        get { self[SettingsKey.self] }
        set { self[SettingsKey.self] = newValue }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

// MARK: - Preview

#if DEBUG
struct MenubarGPTApp_Previews: PreviewProvider {
    static var previews: some View {
        MenubarGPTView()
            .environmentObject(HistoryStore.preview())
            .environmentObject(OpenAIClient())
            .environment(\.settings, Settings.preview)
            .frame(width: 420, height: 520)
    }
}
#endif