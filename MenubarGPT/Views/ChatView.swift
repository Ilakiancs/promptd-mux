import SwiftUI

/// Main chat interface view
struct ChatView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var openAIClient: OpenAIClient
    @Environment(\.settings) private var settings
    
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    
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
                            // Empty state
                            VStack(spacing: 16) {
                                Spacer()
                                
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary.opacity(0.6))
                                
                                VStack(spacing: 8) {
                                    Text("Ready to Chat!")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                    
                                    Text("Ask me anything to get started")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Try asking:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                    
                                    Text("• \"Explain quantum computing\"")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("• \"Write a Swift function\"")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("• \"Help me plan my day\"")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .cornerRadius(8)
                                
                                Spacer()
                            }
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
                // Message input field
                TextEditor(text: $messageText)
                    .font(.body)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 36, maxHeight: 120)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if messageText.isEmpty {
                                Text("Ask me anything...")
                                    .foregroundColor(.secondary)
                                    .allowsHitTesting(false)
                                    .padding(.leading, 12)
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                    )
                    .onSubmit {
                        sendMessage()
                    }
                    .disabled(isLoading)
                
                // Send button
                Button(action: sendMessage) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                    }
                    .foregroundColor(canSendMessage ? .blue : .gray)
                    .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(!canSendMessage)
                .help(isLoading ? "Generating response..." : "Send message")
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
#endif