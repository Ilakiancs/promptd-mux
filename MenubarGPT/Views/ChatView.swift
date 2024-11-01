import SwiftUI

/// Modern chat interface with enhanced UI/UX
struct ChatView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var openAIClient: OpenAIClient
    @Environment(\.settings) private var settings
    
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingWelcome = true
    
    var body: some View {
        VStack(spacing: 0) {
            if !KeychainService.shared.hasApiKey() {
                apiKeyPromptView
            } else {
                // Session indicator and clear button
                if !historyStore.messages.isEmpty {
                    HStack {
                        Text("\(historyStore.messages.count) messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Clear Chat") {
                            clearCurrentSession()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                }
                
                // Chat messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        if historyStore.messages.isEmpty {
                            // Enhanced empty state
                            VStack(spacing: 24) {
                                Spacer()
                                
                                VStack(spacing: 16) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 56, weight: .light))
                                        .foregroundStyle(.blue.gradient)
                                    
                                    VStack(spacing: 8) {
                                        Text("Welcome to promptd-mux")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Text("Your intelligent chat companion")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        SuggestionChip(text: "Explain quantum physics", action: { setSuggestion("Explain quantum physics") })
                                        SuggestionChip(text: "Write a poem", action: { setSuggestion("Write a poem") })
                                    }
                                    HStack(spacing: 12) {
                                        SuggestionChip(text: "Plan my day", action: { setSuggestion("Plan my day") })
                                        SuggestionChip(text: "Code review", action: { setSuggestion("Code review") })
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        } else {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(historyStore.messages) { message in
                                    MessageBubbleSimple(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        
                        // Loading indicator
                        if isLoading {
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                Spacer()
                            }
                            .id("loading")
                            .padding(.horizontal, 12)
                        }
                    }
                    .onChange(of: historyStore.messages.count) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                if let lastMessage = historyStore.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: isLoading) {
                        if isLoading {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Message composer
                messageComposer
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    // MARK: - API Key Prompt
    
    private var apiKeyPromptView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Welcome to MenubarGPT")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("To get started, you'll need to add your OpenAI API key.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Button("Add API Key") {
                        // This will open settings
                        NotificationCenter.default.post(name: .showSettings, object: nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Link("Get API Key from OpenAI", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(24)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Message Composer
    
    private var messageComposer: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                // Enhanced message input field
                TextEditor(text: $messageText)
                    .font(.body)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 40, maxHeight: 120)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isTextFieldFocused ? Color.blue.opacity(0.6) : Color.gray.opacity(0.2), lineWidth: 2)
                    )
                    .overlay(
                        Group {
                            if messageText.isEmpty {
                                Text("Type your message here...")
                                    .foregroundColor(.secondary)
                                    .allowsHitTesting(false)
                                    .padding(.leading, 20)
                                    .padding(.top, 12)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                    )
                    .onSubmit {
                        sendMessage()
                    }
                    .disabled(isLoading)
                    .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                
                // Enhanced send button
                Button(action: sendMessage) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(canSendMessage ? Color.blue : Color.gray.opacity(0.3))
                    .cornerRadius(18)
                }
                .buttonStyle(.plain)
                .disabled(!canSendMessage)
                .help(isLoading ? "Generating response..." : "Send message")
                .scaleEffect(canSendMessage && !isLoading ? 1.0 : 0.9)
                .animation(.spring(response: 0.3), value: canSendMessage)
            }
            
            // Helper text and status
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "command")
                        .font(.caption2)
                    Text("⏎ to send")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Status and model indicator
                HStack(spacing: 8) {
                    if isLoading {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("Generating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Model indicator
                    Text(settings.selectedModel.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                        .help("Current AI model")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Computed Properties
    
    private var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        KeychainService.shared.hasApiKey()
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard canSendMessage, !isLoading else { return }
        
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Create or get current session
        let sessionId = historyStore.currentSessionId ?? historyStore.createSession(with: trimmedMessage)
        
        // Create user message
        let userMessage = Message(
            role: .user,
            content: trimmedMessage,
            sessionId: sessionId
        )
        
        // Add user message to history
        historyStore.addMessage(userMessage)
        
        // Clear input and set loading state
        messageText = ""
        isLoading = true
        
        // Send to OpenAI
        Task {
            await sendToOpenAI(sessionId: sessionId)
        }
    }
    
    @MainActor
    private func sendToOpenAI(sessionId: String) async {
        defer { isLoading = false }
        
        do {
            // Get recent messages for context
            let recentMessages = historyStore.getRecentMessages(for: sessionId, limit: 20)
            
            // Create initial assistant message
            let assistantMessage = Message(
                role: .assistant,
                content: "",
                sessionId: sessionId
            )
            
            // Add assistant message to history
            historyStore.addMessage(assistantMessage)
            
            var fullContent = ""
            
            // Send streaming request to OpenAI
            let response = try await openAIClient.sendStreamingChatCompletion(
                messages: recentMessages,
                model: settings.selectedModel
            ) { partialContent in
                // Update the assistant message content as we receive chunks
                fullContent += partialContent
                historyStore.updateLastMessage(content: fullContent)
            }
            
            // Final update with complete content
            historyStore.updateLastMessage(content: response)
            
            // Refocus text field
            isTextFieldFocused = true
            
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
        isTextFieldFocused = true
    }
    
    private func clearCurrentSession() {
        historyStore.clearMessages()
        isTextFieldFocused = true
    }
    
    private func setSuggestion(_ text: String) {
        messageText = text
        isTextFieldFocused = true
    }
}

// MARK: - Simple Message Bubble (without MarkdownUI dependency)
struct MessageBubbleSimple: View {
    let message: Message
    
    @State private var showingCopySuccess = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                // Assistant avatar
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "brain")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                // Message content
                VStack(alignment: .leading, spacing: 8) {
                    if message.role == .assistant {
                        HStack {
                            Text("Assistant")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    
                    MarkdownView(content: message.content)
                        .textSelection(.enabled)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(messageBackgroundColor)
                .foregroundColor(messageTextColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(message.role == .assistant ? Color.gray.opacity(0.2) : Color.clear, lineWidth: 0.5)
                )
                
                // Timestamp and actions
                HStack(spacing: 8) {
                    Text(message.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if message.role == .assistant {
                        Spacer()
                        
                        // Copy button
                        Button(action: copyMessage) {
                            HStack(spacing: 4) {
                                Image(systemName: showingCopySuccess ? "checkmark" : "doc.on.doc")
                                if showingCopySuccess {
                                    Text("Copied!")
                                        .font(.caption2)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Copy message")
                        .animation(.easeInOut(duration: 0.2), value: showingCopySuccess)
                    }
                }
                .padding(.horizontal, message.role == .user ? 12 : 0)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            } else {
                // User avatar
                Circle()
                    .fill(Color.gray.gradient)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            }
        }
        .contextMenu {
            Button("Copy") {
                copyMessage()
            }
            if message.role == .assistant {
                Button("Copy as Quote") {
                    copyAsQuote()
                }
            }
        }
    }
    
    private var messageBackgroundColor: Color {
        switch message.role {
        case .user:
            return Color.blue
        case .assistant:
            return Color(NSColor.controlBackgroundColor).opacity(0.8)
        case .system:
            return Color.orange.opacity(0.2)
        }
    }
    
    private var messageTextColor: Color {
        switch message.role {
        case .user:
            return .white
        case .assistant, .system:
            return .primary
        }
    }
    

    
    private func copyMessage() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
        
        showingCopySuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCopySuccess = false
        }
    }
    
    private func copyAsQuote() {
        let quotedText = message.content
            .split(separator: "\n")
            .map { "> \($0)" }
            .joined(separator: "\n")
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(quotedText, forType: .string)
        
        showingCopySuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCopySuccess = false
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let showSettings = Notification.Name("showSettings")
}

// MARK: - Preview

// MARK: - Simple Markdown View

struct MarkdownView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseContent(), id: \.id) { block in
                switch block.type {
                case .text:
                    Text(block.content)
                        .font(.system(size: 14, weight: .regular))
                        .textSelection(.enabled)
                case .code:
                    CodeBlockView(code: block.content, language: block.language)
                }
            }
        }
    }
    
    private func parseContent() -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        let lines = content.components(separatedBy: .newlines)
        var currentBlock = ""
        var inCodeBlock = false
        var codeLanguage = ""
        
        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    if !currentBlock.isEmpty {
                        blocks.append(ContentBlock(type: .code, content: currentBlock.trimmingCharacters(in: .whitespacesAndNewlines), language: codeLanguage))
                        currentBlock = ""
                    }
                    inCodeBlock = false
                    codeLanguage = ""
                } else {
                    // Start code block
                    if !currentBlock.isEmpty {
                        blocks.append(ContentBlock(type: .text, content: currentBlock.trimmingCharacters(in: .whitespacesAndNewlines)))
                        currentBlock = ""
                    }
                    inCodeBlock = true
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else {
                if inCodeBlock {
                    currentBlock += line + "\n"
                } else {
                    currentBlock += line + "\n"
                }
            }
        }
        
        if !currentBlock.isEmpty {
            blocks.append(ContentBlock(type: inCodeBlock ? .code : .text, content: currentBlock.trimmingCharacters(in: .whitespacesAndNewlines), language: codeLanguage))
        }
        
        return blocks
    }
    
    struct ContentBlock {
        let id = UUID()
        let type: BlockType
        let content: String
        let language: String
        
        enum BlockType {
            case text
            case code
        }
        
        init(type: BlockType, content: String, language: String = "") {
            self.type = type
            self.content = content
            self.language = language
        }
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String
    
    @State private var showingCopySuccess = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language and copy button
            HStack {
                Text(language.isEmpty ? "Code" : language.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: copyCode) {
                    HStack(spacing: 4) {
                        Image(systemName: showingCopySuccess ? "checkmark" : "doc.on.doc")
                        if showingCopySuccess {
                            Text("Copied!")
                                .font(.caption2)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy code")
                .animation(.easeInOut(duration: 0.2), value: showingCopySuccess)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.05))
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        
        showingCopySuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCopySuccess = false
        }
    }
}

// MARK: - Suggestion Chip Component
struct SuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            // Add subtle hover effect
        }
    }
}

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(HistoryStore.preview())
            .environmentObject(OpenAIClient())
            .environment(\.settings, Settings.preview)
            .frame(width: 420, height: 520)
    }
}
#endif// Feature: add message copy functionality
