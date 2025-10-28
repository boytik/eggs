# 🚀 UIKit Integration Setup Guide

## ✅ Completed Steps

1. **Created Core Services** (`Core/Services/`):
   - `ConfigClient.swift` - handles config endpoint requests
   - `LaunchModeManager.swift` - manages app mode (webview/fan) and caching
   - `Reachability.swift` - network connectivity checks
   - `AppsFlyerHelper.swift` - AppsFlyer integration and payload building
   - `PushPermissionService.swift` - push notification management

2. **Created UI Controllers** (`UI/ViewControllers/`):
   - `RootContainerViewController.swift` - main flow coordinator
   - `WebContainerViewController.swift` - WebView mode with 70pt nav bar
   - `FanticViewController.swift` - fallback native content
   - `NoInternetViewController.swift` - offline screen with retry
   - `PushPermissionViewController.swift` - custom push permission UI

3. **Updated AppDelegate.swift**:
   - Firebase and AppsFlyer initialization
   - Push notification setup
   - Deep links support
   - ATT (App Tracking Transparency) integration

4. **Updated Info.plist**:
   - Added required permissions
   - Configured status bar settings
   - Firebase proxy disabled

5. **Created Podfile** with dependencies:
   - AppsFlyerFramework
   - Firebase/Core & Firebase/Messaging
   - SnapKit

## 🔧 Next Steps (Manual)

### 1. Install Dependencies
```bash
cd "/Users/evgenij/Desktop/eggs"
pod install
```

### 2. Open Workspace
Open `Eggonomics Road.xcworkspace` (NOT .xcodeproj)

### 3. Configure Firebase
- Replace `GoogleService-Info.plist` with your real Firebase config
- Update PROJECT_ID, API_KEY, etc. with actual values

### 4. Configure Bundle ID
- In Xcode, set Bundle Identifier to: `app.egg.economics.com`
- Enable Push Notifications capability
- Enable Background Modes → Remote notifications

### 5. Test Flow
The app will now:
- Start with `RootContainerViewController`
- Check AppsFlyer status on first launch
- If "Non-organic" → try config endpoint → WebView mode
- If "Organic" or config fails → Fan mode (existing ChickLoading flow)
- Cache decisions for subsequent launches

## 🎯 Key Features

- **Branching Logic**: WebView vs Fan mode based on AppsFlyer status
- **Offline Handling**: No Internet screen with retry
- **Push Permissions**: Custom UI before system prompt
- **Deep Links**: Full AppsFlyer and Firebase integration
- **Status Bar**: Hidden globally in WebView mode
- **Caching**: URL and expiration management

## 🐛 Debug Methods

```swift
// Reset all settings (add to debug menu)
LaunchModeManager.shared.resetMode()

// Check current mode
print("Current mode: \(LaunchModeManager.shared.currentMode)")

// Check cached URL
print("Cached URL: \(LaunchModeManager.shared.cachedURL?.absoluteString ?? "none")")
```

## 📱 Testing

1. **First Launch**: Should check AppsFlyer → config endpoint
2. **Subsequent Launches**: Should use cached mode
3. **Offline**: Should show No Internet screen
4. **Push Permissions**: Should show custom screen in WebView mode
5. **Deep Links**: Should open in WebView if in WebView mode

All logs use emojis for easy identification! 🎉
