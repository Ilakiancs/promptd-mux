# Setup Guide

This guide will walk you through setting up MenubarGPT on your Mac.

## 📋 Prerequisites

- macOS 13.0 (Ventura) or later
- An OpenAI account with API access
- About 50MB of free disk space

## Getting Your OpenAI API Key

### Step 1: Create OpenAI Account
1. Visit [OpenAI Platform](https://platform.openai.com)
2. Sign up or log in to your account
3. Complete any required verification steps

### Step 2: Generate API Key
1. Go to [API Keys page](https://platform.openai.com/api-keys)
2. Click "Create new secret key"
3. Give it a descriptive name (e.g., "MenubarGPT")
4. Copy the API key (starts with `sk-`)
5. **Important**: Save this key securely - you won't see it again!

### Step 3: Set Up Billing (if needed)
1. Go to [Billing Settings](https://platform.openai.com/account/billing)
2. Add a payment method
3. Consider setting usage limits for cost control
4. Review pricing for different models

## Installing MenubarGPT

### Option A: Download Pre-built App (Recommended)
1. Download the latest release from [GitHub Releases](https://github.com/menubargpt/menubargpt/releases)
2. Unzip the downloaded file
3. Drag `MenubarGPT.app` to your Applications folder
4. Right-click the app and select "Open" (first time only)

### Option B: Build from Source
1. **Install Xcode** (from Mac App Store)
2. **Clone the repository**:
   ```bash
   git clone https://github.com/menubargpt/menubargpt.git
   cd menubargpt
   ```
3. **Open in Xcode**:
   ```bash
   open MenubarGPT.xcodeproj
   ```
4. **Build and run** (⌘R)

## First Time Setup

### Step 1: Launch the App
1. Find MenubarGPT in your Applications folder
2. Double-click to launch
3. Look for the message icon in your menubar (top-right area)

### Step 2: Add Your API Key
1. Click the MenubarGPT icon in the menubar
2. You'll see a welcome screen asking for an API key
3. Click "Add API Key" to open settings
4. Paste your OpenAI API key in the text field
5. Click "Test & Save" to verify the key works
6. Wait for the green checkmark confirmation

### Step 3: Choose Your Model
In the settings window, select your preferred AI model:

- **GPT-4o Mini** (Recommended)
  - Fast and cost-effective
  - Great for most conversations
  - ~$0.15 per 1M input tokens

- **GPT-4o**
  - Most capable model
  - Best for complex tasks
  - ~$2.50 per 1M input tokens

- **o1-Mini**
  - Advanced reasoning
  - Good for complex problems
  - ~$3.00 per 1M input tokens

### Step 4: Start Chatting
1. Close the settings window
2. Type your first message in the text field
3. Press ⌘⏎ or click the send button
4. Wait for the AI response!

## Keyboard Shortcuts

- `⌘⏎` - Send message
- `⌥⇧G` - Show/hide app (global hotkey)
- `⌘,` - Open settings
- `⌘W` - Close window
- `⌘Q` - Quit app

## Advanced Configuration

### Global Hotkey
1. Open Settings (⌘,)
2. Enable "Global Hotkey" 
3. Press ⌥⇧G from anywhere to open MenubarGPT

### Start at Login
1. Open Settings
2. Enable "Start at Login"
3. MenubarGPT will launch when you log in

### Window Opacity
1. Open Settings
2. Adjust the "Window Opacity" slider
3. Find the perfect transparency level

## 🔒 Privacy & Security

### Data Storage
- **API Key**: Stored securely in macOS Keychain
- **Chat History**: Saved locally in `~/Library/Application Support/MenubarGPT/`
- **Settings**: Stored in macOS UserDefaults

### What's Shared
- **With OpenAI**: Only your messages and selected model
- **With MenubarGPT**: Nothing - no telemetry or analytics
- **With Apple**: Standard app sandbox protections

### Security Features
- App Sandbox enabled
- Network access limited to OpenAI API
- No background data collection
- Open source for full transparency

## Troubleshooting

### App Won't Start
1. Check macOS version (need 13.0+)
2. Try right-clicking app and selecting "Open"
3. Check Console app for error messages

### API Key Issues
**"Invalid API Key" Error**:
- Verify the key starts with `sk-`
- Check you copied the complete key
- Ensure the key hasn't been revoked
- Try creating a new key

**"Rate Limit Exceeded"**:
- Check your OpenAI usage dashboard
- Wait a few minutes and try again
- Consider upgrading your OpenAI plan

### App Not in Menubar
1. Check Activity Monitor for MenubarGPT process
2. Try quitting and restarting the app
3. Reset menubar: `killall SystemUIServer`

### Messages Not Saving
1. Check available disk space
2. Verify app permissions in System Preferences
3. Try quitting and restarting the app

## 📞 Getting Help

If you encounter issues:

1. **Check Common Issues**: Review troubleshooting section above
2. **Search GitHub Issues**: [github.com/menubargpt/menubargpt/issues](https://github.com/menubargpt/menubargpt/issues)
3. **Create New Issue**: Include your setup details and error messages
4. **Join Discussions**: [github.com/menubargpt/menubargpt/discussions](https://github.com/menubargpt/menubargpt/discussions)

### When Reporting Issues
Please include:
- macOS version
- MenubarGPT version
- Steps to reproduce the problem
- Any error messages
- Screenshots if helpful

## You're Ready!

Congratulations! You now have MenubarGPT set up and ready to use. Enjoy having ChatGPT at your fingertips!

### Pro Tips
- Use ⌥⇧G for instant access from anywhere
- Copy code blocks with the copy button
- Try different models for different tasks
- Use the "Open in Browser" button for complex conversations

---

**Need more help?** Check out our [FAQ](FAQ.md) or [create an issue](https://github.com/menubargpt/menubargpt/issues/new).
