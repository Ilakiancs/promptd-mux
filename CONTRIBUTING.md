# Contributing to MenubarGPT

Thank you for your interest in contributing to MenubarGPT! We welcome contributions from the community and are grateful for any help you can provide.

## Getting Started

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9+
- Git

### Development Setup

1. **Fork the Repository**
   ```bash
   # Click the "Fork" button on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/menubargpt.git
   cd menubargpt
   ```

2. **Open in Xcode**
   ```bash
   open MenubarGPT.xcodeproj
   ```

3. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make Your Changes**
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed

5. **Test Your Changes**
   ```bash
   # Build and test in Xcode
   ⌘R  # Build and run
   ⌘U  # Run tests
   ```

6. **Commit and Push**
   ```bash
   git add .
   git commit -m "Add: Description of your changes"
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Go to GitHub and create a pull request
   - Provide a clear description of your changes
   - Link any relevant issues

## 📋 Guidelines

### Code Style

- **Swift Style**: Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **SwiftUI**: Use modern SwiftUI patterns and best practices
- **Naming**: Use clear, descriptive names for variables and functions
- **Comments**: Add documentation for public APIs and complex logic

### Example Code Style

```swift
/// Sends a chat completion request to OpenAI
/// - Parameters:
///   - messages: Array of messages for context
///   - model: The OpenAI model to use
/// - Returns: The assistant's response
/// - Throws: APIError if the request fails
func sendChatCompletion(
    messages: [Message],
    model: OpenAIModel
) async throws -> String {
    // Implementation here
}
```

### Commit Messages

Use the following format for commit messages:

```
Type: Brief description

Longer explanation if needed

- Specific change 1
- Specific change 2

Fixes #123
```

**Types:**
- `Add`: New features or functionality
- `Fix`: Bug fixes
- `Update`: Updates to existing functionality
- `Remove`: Removing code or files
- `Refactor`: Code restructuring without functional changes
- `Docs`: Documentation changes
- `Test`: Adding or updating tests

### Pull Request Guidelines

- **Small Changes**: Keep PRs focused and manageable
- **Clear Description**: Explain what and why you changed something
- **Tests**: Include tests for new functionality
- **Documentation**: Update docs if you change user-facing features
- **No Breaking Changes**: Avoid breaking existing functionality

## Reporting Issues

When reporting issues, please include:

1. **Environment**:
   - macOS version
   - Xcode version
   - App version

2. **Steps to Reproduce**:
   - Clear, step-by-step instructions
   - Expected vs actual behavior

3. **Additional Context**:
   - Screenshots if applicable
   - Error messages
   - Console logs

### Issue Template

```markdown
## Bug Report

**Environment:**
- macOS: 14.0
- Xcode: 15.0
- MenubarGPT: 1.0.0

**Description:**
Brief description of the issue

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Additional Context:**
Any other relevant information
```

## Feature Requests

We welcome feature requests! Please:

1. **Check Existing Issues**: Make sure the feature hasn't been requested
2. **Provide Context**: Explain the use case and why it's useful
3. **Be Specific**: Clear description of what you want
4. **Consider Alternatives**: Mention any workarounds or alternatives

## Architecture

### Project Structure

```
MenubarGPT/
├── MenubarGPTApp.swift          # Main app entry point
├── Models/                      # Data models
├── Services/                    # Business logic and API services
├── Views/                       # SwiftUI views and components
├── Persistence/                 # Data storage logic
└── Tests/                       # Unit and integration tests
```

### Key Components

- **MenubarGPTApp**: Main app structure with MenuBarExtra
- **ChatView**: Primary chat interface
- **OpenAIClient**: API communication service
- **KeychainService**: Secure credential storage
- **HistoryStore**: Local data persistence

### Design Patterns

- **MVVM**: Model-View-ViewModel architecture
- **Dependency Injection**: Services injected via @EnvironmentObject
- **Single Source of Truth**: Centralized state management
- **Reactive Programming**: Using Combine for data flow

## 🧪 Testing

### Running Tests

```bash
# In Xcode
⌘U  # Run all tests

# Command line
xcodebuild test -project MenubarGPT.xcodeproj -scheme MenubarGPT
```

### Writing Tests

- Write unit tests for new functionality
- Test edge cases and error conditions
- Use descriptive test names
- Mock external dependencies

### Test Structure

```swift
import XCTest
@testable import MenubarGPT

final class OpenAIClientTests: XCTestCase {
    var client: OpenAIClient!
    
    override func setUp() {
        super.setUp()
        client = OpenAIClient()
    }
    
    func testValidApiKey() async throws {
        // Given
        let validKey = "sk-test123"
        
        // When
        let isValid = try await client.testApiKey(validKey)
        
        // Then
        XCTAssertTrue(isValid)
    }
}
```

## 🔒 Security

### Security Considerations

- Never commit API keys or sensitive data
- Use KeychainService for secure storage
- Validate all user inputs
- Follow Apple's security guidelines

### Reporting Security Issues

For security issues, please email security@menubargpt.com instead of creating a public issue.

## Resources

### Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [MenuBarExtra Guide](https://developer.apple.com/documentation/swiftui/menubarextra)

### Tools
- [SwiftLint](https://github.com/realm/SwiftLint) - Code style enforcement
- [SF Symbols](https://developer.apple.com/sf-symbols/) - System icons

## Recognition

Contributors will be recognized in:
- GitHub contributors list
- App credits (for significant contributions)
- Release notes

## Questions?

If you have questions about contributing:

- [GitHub Discussions](https://github.com/menubargpt/menubargpt/discussions)
- [Email](mailto:contributors@menubargpt.com)
- [Twitter](https://twitter.com/menubargpt)

Thank you for contributing to MenubarGPT!
