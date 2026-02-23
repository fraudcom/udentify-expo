# Expo Video Call Module

Expo module providing video call functionality using the Udentify SDK. This module enables real-time video communication with camera/microphone controls and UI customization.

## Platform Support

- ✅ iOS (15.1+)
- ✅ Android (SDK 21+)
- ⚠️ Web (Not supported)

## Features

- Real-time video communication
- Camera controls (toggle, switch front/back)
- Microphone controls (mute/unmute)
- Permission management
- UI customization (colors, labels)
- WebSocket-based connection
- Transaction-based sessions
- Event-driven status monitoring
- Comprehensive error handling

## Installation

This module is part of the FraudExpo project and is automatically linked.

For standalone use:

```bash
# Install the module
npm install ./modules/expo-video-call

# Rebuild the project
npx expo prebuild --clean
```

## iOS Setup

### Requirements
- iOS 15.1 or higher
- Physical device (simulators not supported for video calls)
- Xcode 14.0+

### Permissions
Add to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access for video calling</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access for audio during video calls</string>
```

### Dependencies
The iOS implementation depends on:
- `UdentifyCore`: Provides UdentifyCommons.xcframework
- `UdentifyVC`: Video call framework (included as source files)

For detailed iOS implementation docs, see [ios/README.md](ios/README.md)

## Android Setup

### Requirements
- Android SDK 21+
- Physical device recommended

### Permissions
Automatically added via AndroidManifest.xml:
- `android.permission.CAMERA`
- `android.permission.RECORD_AUDIO`
- `android.permission.INTERNET`
- `android.permission.READ_PHONE_STATE`

### Dependencies
- `vc-25.2.1.aar`: UdentifyVC Android library (in `android/libs/`)

## Usage

### Basic Example

```typescript
import * as ExpoVideoCall from 'expo-video-call';

// Check permissions
const checkPermissions = async () => {
  const permissions = await ExpoVideoCall.checkPermissions();
  console.log('Permissions:', permissions);
  
  if (!permissions.hasCameraPermission || !permissions.hasRecordAudioPermission) {
    const result = await ExpoVideoCall.requestPermissions();
    console.log('Permission request result:', result);
  }
};

// Start video call
const startCall = async () => {
  try {
    const credentials = {
      serverURL: 'https://api.udentify.com',
      wssURL: 'wss://api.udentify.com/v1',
      userID: 'user-123',
      transactionID: 'transaction-456',
      clientName: 'MyApp',
      idleTimeout: '30'
    };
    
    const result = await ExpoVideoCall.startVideoCall(credentials);
    console.log('Call started:', result);
  } catch (error) {
    console.error('Failed to start call:', error);
  }
};

// End video call
const endCall = async () => {
  const result = await ExpoVideoCall.endVideoCall();
  console.log('Call ended:', result);
};

// Control camera
const toggleCamera = async () => {
  const isEnabled = await ExpoVideoCall.toggleCamera();
  console.log('Camera enabled:', isEnabled);
};

const switchCamera = async () => {
  const success = await ExpoVideoCall.switchCamera();
  console.log('Camera switched:', success);
};

// Control microphone
const toggleMicrophone = async () => {
  const isEnabled = await ExpoVideoCall.toggleMicrophone();
  console.log('Microphone enabled:', isEnabled);
};
```

### UI Customization

```typescript
await ExpoVideoCall.setVideoCallConfig({
  backgroundColor: '#000000',
  textColor: '#FFFFFF',
  pipViewBorderColor: '#00FF00',
  notificationLabelDefault: 'Waiting for agent...',
  notificationLabelCountdown: 'Call starting in %d seconds',
  notificationLabelTokenFetch: 'Connecting...'
});
```

### Complete Integration Example

See [VideoCallTab.tsx](../../components/VideoCallTab.tsx) in the FraudExpo test app for a complete implementation example.

## API Reference

### Methods

#### `checkPermissions(): Promise<VideoCallPermissionStatus>`
Check current permission status for camera, microphone, and other required permissions.

**Returns:**
```typescript
{
  hasCameraPermission: boolean;
  hasPhoneStatePermission: boolean;
  hasInternetPermission: boolean;
  hasRecordAudioPermission: boolean;
}
```

#### `requestPermissions(): Promise<string>`
Request necessary permissions from the user.

**Returns:** `'granted'`, `'denied'`, or error message

#### `startVideoCall(credentials: VideoCallCredentials): Promise<VideoCallResult>`
Start a video call with the provided credentials.

**Parameters:**
```typescript
{
  serverURL: string;          // Udentify server URL
  wssURL: string;            // WebSocket URL
  userID: string;            // Unique user identifier
  transactionID: string;     // Transaction ID from server
  clientName: string;        // Client application name
  idleTimeout: string;       // Timeout in seconds (default: "30")
}
```

**Returns:**
```typescript
{
  success: boolean;
  status?: string;           // 'connecting', 'connected', etc.
  transactionID?: string;
}
```

#### `endVideoCall(): Promise<VideoCallResult>`
End the current video call.

#### `getVideoCallStatus(): Promise<string>`
Get the current status of the video call.

**Returns:** `'idle'`, `'connecting'`, `'connected'`, `'disconnected'`, etc.

#### `setVideoCallConfig(config: VideoCallConfig): Promise<void>`
Configure UI settings for the video call.

**Parameters:**
```typescript
{
  backgroundColor?: string;              // Hex color (e.g., "#000000")
  textColor?: string;                   // Hex color
  pipViewBorderColor?: string;          // Hex color for PIP view border
  notificationLabelDefault?: string;     // Default notification text
  notificationLabelCountdown?: string;   // Countdown text (use %d for seconds)
  notificationLabelTokenFetch?: string;  // Token fetch notification text
}
```

#### `toggleCamera(): Promise<boolean>`
Toggle camera on/off.

**Returns:** Current camera state (true = on, false = off)

#### `switchCamera(): Promise<boolean>`
Switch between front and back camera.

**Returns:** Success state

#### `toggleMicrophone(): Promise<boolean>`
Toggle microphone on/off.

**Returns:** Current microphone state (true = on, false = off)

#### `dismissVideoCall(): Promise<void>`
Dismiss the video call UI.

### Types

#### VideoCallCredentials
```typescript
interface VideoCallCredentials {
  serverURL: string;
  wssURL: string;
  userID: string;
  transactionID: string;
  clientName: string;
  idleTimeout: string;
}
```

#### VideoCallConfig
```typescript
interface VideoCallConfig {
  backgroundColor?: string;
  textColor?: string;
  pipViewBorderColor?: string;
  notificationLabelDefault?: string;
  notificationLabelCountdown?: string;
  notificationLabelTokenFetch?: string;
}
```

#### VideoCallPermissionStatus
```typescript
interface VideoCallPermissionStatus {
  hasCameraPermission: boolean;
  hasPhoneStatePermission: boolean;
  hasInternetPermission: boolean;
  hasRecordAudioPermission: boolean;
}
```

#### VideoCallResult
```typescript
interface VideoCallResult {
  success: boolean;
  status?: string;
  transactionID?: string;
}
```

### Events

The module emits the following events (for advanced usage):

- `VideoCall_onStatusChanged`: Call status changes
- `VideoCall_onError`: Error events
- `VideoCall_onUserStateChanged`: User state changes
- `VideoCall_onParticipantStateChanged`: Participant state changes
- `VideoCall_onVideoCallEnded`: Call ended
- `VideoCall_onVideoCallDismissed`: UI dismissed

## Project Structure

```
expo-video-call/
├── README.md                          # This file
├── IMPLEMENTATION_SUMMARY.md          # Detailed implementation notes
├── expo-module.config.json            # Module configuration
├── index.ts                          # Main entry point
├── src/
│   ├── ExpoVideoCall.types.ts        # TypeScript type definitions
│   ├── ExpoVideoCallModule.ts        # Module declaration
│   └── ExpoVideoCallModule.web.ts    # Web stub (not supported)
├── ios/
│   ├── README.md                     # iOS implementation docs
│   ├── ExpoVideoCallModule.swift     # Main iOS module
│   ├── VideoCallBundleHelper.swift   # Localization helper
│   ├── CustomVideoCallSettings.swift # UI customization
│   ├── ExpoVideoCall.podspec         # CocoaPods spec
│   ├── Localizable.strings           # Localization strings
│   ├── Resources/
│   │   └── PrivacyInfo.xcprivacy    # App Store privacy manifest
│   └── Frameworks/
│       └── UdentifyVC/               # Video call framework
└── android/
    ├── build.gradle                  # Android build config
    ├── libs/
    │   └── vc-25.2.1.aar            # UdentifyVC Android library
    └── src/main/
        ├── AndroidManifest.xml       # Permissions
        └── java/com/videocallmodule/
            ├── VideoCallModule.kt    # Main Android module
            └── VideoCallOperatorImpl.kt  # Delegate implementation
```

## Troubleshooting

### iOS Issues

#### Module not found
```bash
cd ios
pod install
npx expo prebuild --clean
```

#### Camera/Microphone not working
- Verify Info.plist has permission descriptions
- Check Settings > [Your App] > Permissions
- Test on physical device (not simulator)

#### Build errors
- Clean build folder in Xcode
- Delete `ios/Pods` and reinstall
- Ensure UdentifyCore is properly linked

### Android Issues

#### AAR not found
- Verify `vc-25.2.1.aar` is in `android/libs/`
- Check `build.gradle` includes libs directory

#### Permissions denied
- Request permissions before starting call
- Check AndroidManifest.xml

### General Issues

#### Connection fails
- Verify serverURL and wssURL are correct
- Check transaction ID is valid and not expired
- Ensure network connectivity

#### Video call UI doesn't appear
- Check if call was started successfully
- Verify credentials are valid
- Check console for error messages

## Testing

### Recommended Testing Flow

1. **Permission Testing**
   - Check permissions on fresh install
   - Request permissions
   - Verify permissions granted

2. **Call Lifecycle**
   - Start call with valid credentials
   - Verify UI appears
   - Check video/audio streaming
   - End call properly

3. **Controls Testing**
   - Toggle camera on/off
   - Switch between front/back camera
   - Toggle microphone on/off

4. **Error Scenarios**
   - Invalid credentials
   - Network disconnection
   - Permission denial
   - Timeout handling

5. **UI Customization**
   - Apply custom colors
   - Test notification labels
   - Verify PIP view styling

### Test on Real Devices

⚠️ **IMPORTANT**: Always test on physical devices, never on simulators/emulators.

- iOS: Use Xcode device deployment or EAS Build
- Android: Use `adb` connected device or EAS Build

## Performance Considerations

- **Memory**: Video streaming requires significant memory
- **Network**: Stable internet connection required (4G/WiFi recommended)
- **Battery**: Video calls consume battery quickly
- **Permissions**: Request permissions early in user flow

## Comparison with Other Implementations

| Feature | Expo | React Native | Flutter |
|---------|------|--------------|---------|
| API | ExpoModulesCore | React Native bridge | Flutter MethodChannel |
| Language | Swift | Swift + Objective-C | Swift + Dart |
| Integration | Auto-linked | Manual linking | Pub package |
| Events | Expo Events | RCTEventEmitter | EventChannel |
| Config | expo-module.config.json | podspec + package.json | pubspec.yaml |

All implementations provide the same functionality and API surface.

## Contributing

When modifying this module:

1. Follow project coding standards (see project root rules)
2. Update both iOS and Android implementations
3. Test on physical devices
4. Update documentation
5. No emojis in code or logs
6. Use professional logging format: `ClassName - message`

## License

Proprietary - Fraud.com

## Support

For issues or questions:
- Check troubleshooting section above
- Review implementation docs in `ios/README.md`
- See test app implementation in `../../components/VideoCallTab.tsx`
- Contact Udentify support for SDK-related issues

## Version History

### v1.0.0 (Current)
- Initial iOS and Android implementation
- Complete feature parity with React Native version
- Comprehensive documentation
- Production-ready

---

**Note**: This module requires valid Udentify credentials to function. Contact Udentify for server access and transaction ID generation.

