# MenubarGPT

A native macOS menubar application that provides quick access to ChatGPT conversations. Built with SwiftUI and designed for seamless integration into your workflow.

## Features

**Native macOS Experience**
- Lives in your menubar for instant access
- Fixed 420×520 window that doesn't interfere with your workspace
- App Sandbox enabled for security

**Secure API Key Management**
- API keys stored securely in macOS Keychain
- One-click API key validation
- No sensitive data stored in plain text

**Advanced Chat Interface**
- Real-time streaming responses
- Markdown rendering with syntax-highlighted code blocks
- Copy code blocks with one click
- Message history persistence (last 50 messages per session)

**Customizable Settings**
- Support for multiple OpenAI models (GPT-4o, GPT-4o Mini, o1-mini)
- Model switching on the fly
- Quick access to OpenAI in browser

**Production Ready**
- Comprehensive error handling with retry logic
- Network error recovery
- Rate limiting awareness
- Unit tested with mock API client

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for building)
- OpenAI API key

## Quick Start

### 1. Get Your OpenAI API Key

1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create a new API key
3. Copy the key (starts with `sk-`)

### 2. Build and Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/menubargpt/menubargpt.git
   cd menubargpt
   ```

2. **Open in Xcode:**
   ```bash
   open MenubarGPT.xcodeproj
   ```

3. **Build and run:**
   - Select the MenubarGPT scheme
   - Press `Cmd+R` to build and run
   - The app will appear in your menubar (look for the message icon)

### 3. Configure API Key

1. Click the MenubarGPT icon in your menubar
2. Click "Add API Key" button
3. Paste your OpenAI API key
4. Click "Test & Save"
5. Start chatting!

## Usage

### Basic Chat
- Click the menubar icon to open the chat window
- Type your message in the text area at the bottom
- Press `Cmd+Enter` to send (or click the send button)
- Watch as the AI responds in real-time with streaming

### Managing Conversations
- **Clear Chat**: Click "Clear Chat" to start a new conversation
- **Message History**: Last 50 messages are automatically saved per session
- **Persistent Storage**: Conversations are saved to `~/Library/Application Support/MenubarGPT/`

### Settings
- Click the gear icon in the header to open settings
- **Change Model**: Select between GPT-4o, GPT-4o Mini, or o1-mini
- **Update API Key**: Change or remove your stored API key
- **Quick Links**: Access OpenAI platform directly

### Keyboard Shortcuts
- `Cmd+Enter`: Send message
- `Cmd+,`: Open settings (when window is focused)

## Architecture

The app follows a clean, modular architecture:

```
MenubarGPT/
├── Models/
│   ├── Message.swift          # Message data model
│   └── Settings.swift         # App settings and OpenAI models
├── Services/
│   ├── KeychainService.swift  # Secure API key storage
│   └── OpenAIClient.swift     # OpenAI API communication
├── Views/
│   ├── ChatView.swift         # Main chat interface
│   └── SettingsView.swift     # Settings and configuration
├── Persistence/
│   └── HistoryStore.swift     # Message persistence and session management
└── Tests/
    ├── MockOpenAIClient.swift # Mock for testing
    └── ChatTests.swift        # Unit tests
```

### Key Components

**OpenAI Client**
- Supports both streaming and non-streaming requests
- Comprehensive error handling with retry logic
- Rate limiting awareness with backoff
- Network resilience

**Keychain Service**
- Secure storage using macOS Keychain Services
- Service: `com.menubargpt.api`
- Account: `OPENAI_API_KEY`
- Automatic validation

**History Store**
- JSON-based persistence to Application Support directory
- Session management with automatic cleanup
- Optimized for performance with lazy loading

## Development

### Running Tests

The project includes unit tests with a mock OpenAI client:

```bash
# In Xcode
Cmd+U

# Or via xcodebuild
xcodebuild test -scheme MenubarGPT -destination 'platform=macOS'
```

### Project Structure

- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **URLSession**: Native HTTP client with streaming support
- **Keychain Services**: Secure credential storage
- **XCTest**: Unit testing framework

### Building for Distribution

1. **Archive the app:**
   ```bash
   xcodebuild archive -scheme MenubarGPT -archivePath MenubarGPT.xcarchive
   ```

2. **Export for distribution:**
   ```bash
   xcodebuild -exportArchive -archivePath MenubarGPT.xcarchive -exportPath . -exportOptionsPlist ExportOptions.plist
   ```

## Security & Privacy

- **Sandbox**: App runs in macOS App Sandbox with minimal permissions
- **Network**: Only outgoing connections allowed (no servers/listening)
- **API Keys**: Stored in macOS Keychain, never in UserDefaults or files
- **Logging**: No conversation data logged in release builds
- **Data**: All chat data stored locally on your device

## Troubleshooting

### Common Issues

**"API Key Invalid" Error**
- Verify your API key is correct (starts with `sk-`)
- Check your OpenAI account has available credits
- Ensure API key has chat completion permissions

**"Rate Limited" Error**
- You've exceeded OpenAI's rate limits
- Wait the specified time before retrying
- Consider upgrading your OpenAI plan

**App Not Appearing in Menubar**
- Check if the app is running in Activity Monitor
- Restart the app if needed
- Verify macOS version compatibility (14.0+)

**Network Connection Issues**
- Check your internet connection
- Verify firewall settings allow outgoing HTTPS
- Try changing networks to rule out corporate restrictions

### Reset Everything

To completely reset the app:

1. **Remove API key:**
   ```bash
   security delete-generic-password -s "com.menubargpt.api" -a "OPENAI_API_KEY"
   ```

2. **Remove data:**
   ```bash
   rm -rf ~/Library/Application\ Support/MenubarGPT/
   ```

3. **Remove preferences:**
   ```bash
   defaults delete com.menubargpt.app.MenubarGPT
   ```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- Email: support@menubargpt.com
- Issues: [GitHub Issues](https://github.com/menubargpt/menubargpt/issues)
- Discussions: [GitHub Discussions](https://github.com/menubargpt/menubargpt/discussions)

---

**Made for the macOS community**