# Release Guide

This guide outlines the process for creating and publishing releases of MenubarGPT.

## Building for Release

### Prerequisites
- Xcode 15.0 or later
- macOS Developer Account (for notarization)
- Clean environment (no local modifications)

### Build Process

1. **Update Version Numbers**
   ```bash
   # Update CFBundleShortVersionString and CFBundleVersion in Info.plist
   # Example: 1.0.0 (build 100)
   ```

2. **Create Release Build**
   ```bash
   # Clean build directory
   rm -rf ~/Library/Developer/Xcode/DerivedData/MenubarGPT*
   
   # Build release version
   xcodebuild -project MenubarGPT.xcodeproj \
     -scheme MenubarGPT \
     -configuration Release \
     -archivePath MenubarGPT.xcarchive \
     archive
   
   # Export app
   xcodebuild -exportArchive \
     -archivePath MenubarGPT.xcarchive \
     -exportPath ./Release \
     -exportOptionsPlist ExportOptions.plist
   ```

3. **Code Signing & Notarization**
   ```bash
   # Sign the app (if not done automatically)
   codesign --force --deep --sign "Developer ID Application: Your Name" MenubarGPT.app
   
   # Create DMG
   hdiutil create -volname "MenubarGPT" -srcfolder MenubarGPT.app -ov -format UDZO MenubarGPT.dmg
   
   # Notarize (requires Apple Developer account)
   xcrun notarytool submit MenubarGPT.dmg \
     --apple-id your@email.com \
     --password @keychain:AC_PASSWORD \
     --team-id TEAMID \
     --wait
   
   # Staple notarization
   xcrun stapler staple MenubarGPT.dmg
   ```

## 📦 Release Packaging

### Files to Include
- `MenubarGPT.dmg` - Signed and notarized installer
- `README.md` - Main documentation
- `CHANGELOG.md` - Version history
- `LICENSE` - MIT license

### DMG Contents
- `MenubarGPT.app` - The application
- `Applications` symlink - For easy installation
- Background image (optional)
- Volume icon (optional)

## GitHub Release Process

### 1. Prepare Release Notes
```markdown
## MenubarGPT v1.0.0

### New Features
- Native macOS menubar integration
- Secure API key storage in Keychain
- Support for GPT-4o, GPT-4o Mini, and o1-Mini
- Local chat history persistence
- Beautiful SwiftUI interface

### Bug Fixes
- Fixed startup crash on some systems
- Improved error handling for network issues
- Better memory management

### Technical Changes
- Updated to Swift 5.9
- Minimum macOS version: 13.0
- App Sandbox enabled for security
```

### 2. Create Git Tag
```bash
# Create and push tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### 3. Create GitHub Release
1. Go to GitHub repository
2. Click "Releases" → "Create a new release"
3. Choose the tag you just created
4. Add release title: "MenubarGPT v1.0.0"
5. Paste release notes
6. Upload the DMG file
7. Mark as "Latest release"
8. Publish

## Testing Checklist

Before releasing, verify:

### Functionality
- [ ] App launches successfully
- [ ] API key setup works
- [ ] All AI models respond correctly
- [ ] Chat history persists
- [ ] Settings save properly
- [ ] Copy/paste functions work
- [ ] Keyboard shortcuts work
- [ ] App quits cleanly

### UI/UX
- [ ] All buttons respond
- [ ] Text is readable and properly sized
- [ ] Animations are smooth
- [ ] Loading indicators appear
- [ ] Error messages are helpful
- [ ] Empty states are informative

### Security
- [ ] App is properly sandboxed
- [ ] API keys stored in Keychain
- [ ] No sensitive data in logs
- [ ] Network requests go only to OpenAI
- [ ] File permissions are minimal

### Platform
- [ ] Works on macOS 13.0+
- [ ] Intel and Apple Silicon compatible
- [ ] No external dependencies
- [ ] Proper app signing
- [ ] Notarization successful

## 📋 Release Checklist

### Pre-Release
- [ ] All tests pass
- [ ] Code review completed
- [ ] Version numbers updated
- [ ] Changelog updated
- [ ] Documentation updated
- [ ] Security audit passed

### Release
- [ ] Clean build created
- [ ] App signed and notarized
- [ ] DMG created and tested
- [ ] Git tag created
- [ ] GitHub release published
- [ ] Release notes accurate

### Post-Release
- [ ] Release announced on social media
- [ ] Documentation website updated
- [ ] Monitor for issues
- [ ] Respond to user feedback
- [ ] Plan next version features

## Troubleshooting

### Common Build Issues

**Code Signing Errors**:
```bash
# Check signing identity
security find-identity -v -p codesigning

# Re-sign manually
codesign --force --deep --sign "Developer ID Application" MenubarGPT.app
```

**Notarization Failures**:
```bash
# Check notarization status
xcrun notarytool history --apple-id your@email.com

# Get detailed logs
xcrun notarytool log SUBMISSION_ID --apple-id your@email.com
```

**DMG Creation Issues**:
```bash
# Create DMG with specific settings
hdiutil create -volname "MenubarGPT" \
  -srcfolder MenubarGPT.app \
  -fs HFS+ \
  -format UDZO \
  -o MenubarGPT.dmg
```

### Version Management
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Increment build number for each build
- Keep version consistent across all files

## Version History

### v1.0.0 (2024-01-XX)
- Initial public release
- Core chat functionality
- Basic UI implementation

### v1.1.0 (TBD)
- Streaming responses
- Session management
- Export/import features

---

For questions about the release process, contact the maintainers or create an issue.

