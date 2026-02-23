# Expo Video Call iOS Module

This directory contains the iOS implementation of the Expo Video Call module, providing video calling functionality using the UdentifyVC framework.

## Structure

```
ios/
├── ExpoVideoCallModule.swift          # Main Expo module implementation
├── VideoCallBundleHelper.swift        # Localization bundle helper
├── CustomVideoCallSettings.swift      # UI customization settings
├── ExpoVideoCall.podspec              # CocoaPods specification
├── Localizable.strings                # Localization strings
├── Resources/
│   └── PrivacyInfo.xcprivacy         # App Store privacy manifest
└── Frameworks/
    └── UdentifyVC/                    # UdentifyVC framework source files
        ├── Controllers/
        │   └── VCCameraController.swift
        ├── Enums/
        │   ├── ErrMessage.swift
        │   └── Localization.swift
        ├── Extensions/
        │   └── String_Ext.swift
        ├── Models/
        │   ├── LocalizationConfiguration.swift
        │   ├── TaskEntry.swift
        │   ├── VCCameraSwitchButtonStyle.swift
        │   ├── VCError.swift
        │   ├── VCMuteButtonStyle.swift
        │   ├── VCSettings.swift
        │   └── VideoCallSignal.swift
        └── Services/
            └── TokenService.swift
```

## Key Components

### ExpoVideoCallModule.swift
The main module file that:
- Implements the Expo Modules Core protocol
- Exposes all video call methods to JavaScript
- Manages video call lifecycle (start, end, status)
- Handles permissions (camera, microphone)
- Provides camera and microphone controls
- Emits events for state changes and errors

### VideoCallBundleHelper.swift
Handles localization by:
- Managing the localization bundle
- Providing string lookup functionality
- Falling back to main bundle when needed

### CustomVideoCallSettings.swift
Manages UI customization:
- Converts hex colors to UIColor
- Creates VCSettings with custom styling
- Handles localization bundle integration
- Configures PIP view, buttons, and text styles

### VideoCallOperatorImpl
Implements `VCCameraControllerDelegate` to:
- Handle video call state changes
- Manage participant states
- Process errors
- Emit events to JavaScript layer

## Dependencies

- **ExpoModulesCore**: Required for Expo module integration
- **UdentifyCore**: Provides UdentifyCommons framework with core SDK functionality
- **UdentifyVC**: Video call framework (included as source files)

## Features

### Implemented Methods
- `checkPermissions()`: Check camera and microphone permissions
- `requestPermissions()`: Request necessary permissions
- `startVideoCall(credentials)`: Start a video call session
- `endVideoCall()`: End the current video call
- `getVideoCallStatus()`: Get current call status
- `setVideoCallConfig(config)`: Configure UI settings
- `toggleCamera()`: Toggle camera on/off
- `switchCamera()`: Switch between front/back camera
- `toggleMicrophone()`: Toggle microphone on/off
- `dismissVideoCall()`: Dismiss the video call UI

### Event Emission
The module emits the following events:
- `VideoCall_onUserStateChanged`: User state changes (initiating, connecting, connected, etc.)
- `VideoCall_onParticipantStateChanged`: Participant state changes (agent/supervisor)
- `VideoCall_onError`: Error events
- `VideoCall_onVideoCallEnded`: Call end event
- `VideoCall_onVideoCallDismissed`: UI dismissal event

## iOS Requirements

- iOS 15.1+
- Swift 5.0+
- Camera and Microphone permissions in Info.plist:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>This app requires access to the camera for video calling.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>This app requires access to the microphone for audio during video calls.</string>
  ```

## Installation

The module is automatically integrated when you build the Expo app. The podspec file ensures:
1. All Swift source files are included
2. UdentifyVC framework files are preserved
3. Localization resources are bundled
4. Privacy manifest is included

## Localization

The module supports localization through `Localizable.strings` which includes:
- Notification labels (default, countdown, token fetch)
- Status strings (idle, connecting, connected, etc.)
- Control button labels
- Participant labels
- Error messages
- Instructions
- Quality indicators
- Session status strings
- Permission-related strings

To customize localization:
1. Modify `Localizable.strings` with your translations
2. Pass `tableName` in `setVideoCallConfig` if using custom table name

## UI Customization

Customize the UI by calling `setVideoCallConfig` with:
```typescript
{
  backgroundColor: "#000000",           // Background color (hex)
  textColor: "#FFFFFF",                // Text color (hex)
  pipViewBorderColor: "#FFFFFF",       // PIP view border color (hex)
  notificationLabelDefault: "...",     // Default notification text
  notificationLabelCountdown: "...",   // Countdown text (use %d for seconds)
  notificationLabelTokenFetch: "...",  // Token fetch text
}
```

## Architecture

The implementation follows the same pattern as the React Native video-call-rn-library:

1. **ExpoVideoCallModule** - Main entry point, handles Expo-specific integration
2. **VideoCallOperatorImpl** - Implements delegate pattern for UdentifyVC callbacks
3. **CustomVideoCallSettings** - Handles UI customization and localization
4. **VideoCallBundleHelper** - Manages localization bundles

The module uses UdentifyCommons.framework (provided by UdentifyCore dependency) and includes UdentifyVC source files directly.

## Differences from React Native Implementation

1. Uses `ExpoModulesCore.Module` instead of `RCTEventEmitter`
2. Uses Expo's `AsyncFunction` instead of `RCT_EXPORT_METHOD`
3. Uses Expo's `Events` declaration instead of `supportedEvents`
4. Event emission uses `sendEvent` method provided by Expo
5. No Objective-C bridge file needed (pure Swift)

## Testing on Real Devices

Per project rules, always test on physical devices:
- iOS: Connect device and build with Xcode or EAS
- Never use simulators for production testing
- Verify camera, microphone, and network functionality on real hardware

## Logging

All logs follow the format: `ClassName - [message]`
Examples:
- `ExpoVideoCallModule - Starting video call...`
- `VideoCallOperatorImpl - User state changed: connected`

No emojis or debug clutter in production logs.

## Privacy Manifest

The `Resources/PrivacyInfo.xcprivacy` file declares:
- Camera usage for video calling
- Microphone usage for audio
- Network usage for WebRTC communication

This is required for App Store submission.

## Troubleshooting

### Module not found
- Ensure `expo-video-call` is in your app's dependencies
- Run `npx expo prebuild --clean`

### Camera/Microphone permissions denied
- Check Info.plist has required usage descriptions
- Request permissions before starting call

### Video call fails to start
- Verify credentials (serverURL, wssURL, transactionID)
- Check network connectivity
- Ensure UdentifyCore dependency is properly linked

### Localization not working
- Verify Localizable.strings is included in bundle
- Check bundle resource configuration in podspec
- Test localization bundle loading in VideoCallBundleHelper

