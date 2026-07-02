# flutter_checkin_sdk

Production-ready Flutter plugin for the [Checkin.com (GetID) native SDK](https://dev.checkin.com/docs/getid-native-sdk-1) on Android and iOS.

## Features

- Clean Dart API with repository and platform interface layers
- `MethodChannel` for commands, `EventChannel` for SDK callbacks
- Strongly typed models, events, and exceptions
- Android (Kotlin) and iOS (Swift) implementations
- Example app with Riverpod state management

## Supported platforms

| Platform | Minimum version | Native SDK |
|----------|-----------------|------------|
| Android  | API 21+         | `ee.getid:getidlib:4.2.2` |
| iOS      | 16.0+           | `GetID 4.1.3` |

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_checkin_sdk:
    path: ../flutter_checkin_sdk # or pub.dev once published
```

### Android

The plugin bundles the Checkin.com Android SDK dependency. Ensure your project can resolve the GetID Maven repositories (the example app adds them in `android/build.gradle.kts`):

```kotlin
maven { url = uri("https://jitpack.io") }
maven { url = uri("https://cdn.getid.cloud/sdk/android") }
```

#### `android/gradle.properties`

The GetID SDK pulls in dependencies (including `bcprov-jdk18on`) that can break Android builds when Jetifier is enabled. Update your **host app** `android/gradle.properties` as follows:

| Property | Recommended value | Why |
|----------|-------------------|-----|
| `android.enableJetifier` | `false` | Jetifier fails on `bcprov-jdk18on` (newer Java bytecode) from the GetID SDK. Modern AndroidX projects no longer need Jetifier. |
| `android.jetifier.ignorelist` | `protobuf-lite,protobuf-javalite,bcprov-jdk18on` | Safeguard if Jetifier is re-enabled: exclude BouncyCastle JARs from transformation. |

**Typical Flutter default:**
```properties
android.enableJetifier=true
android.jetifier.ignorelist=protobuf-lite,protobuf-javalite
```

**Recommended change when using this plugin:**
```properties
android.enableJetifier=false
android.jetifier.ignorelist=protobuf-lite,protobuf-javalite,bcprov-jdk18on
```

Add required permissions to your app's `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
```

If your flow uses NFC document reading, also add:

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

Add the following to your app's `android/app/build.gradle` (or `build.gradle.kts`) to avoid duplicate manifest merge conflicts:

```gradle
android {
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
        resources {
            excludes += ['META-INF/versions/9/OSGI-INF/MANIFEST.MF']
        }
    }
}
```

### iOS

The plugin depends on the Checkin.com iOS SDK via CocoaPods:

```ruby
pod 'GetID', podspec: 'https://cdn.getid.cloud/sdk/ios/4.1.3/GetID.podspec'
```

Add the following to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to capture identity documents and perform liveness checks.</string>
<key>UIDesignRequiresCompatibility</key>
<true/>
```

If your flow includes NFC, also add `NFCReaderUsageDescription`, enable the **Near Field Communication Tag Reading** capability, and configure ISO 7816 identifiers as described in the [iOS SDK documentation](https://dev.checkin.com/docs/getid-ios-sdk).

## Initialization

The native SDK does not expose a separate initialize method. The plugin's `initialize()` call prepares the platform channel bridge and event stream.

```dart
final sdk = FlutterCheckinSdk();
await sdk.initialize();
```

## Example usage

```dart
import 'package:flutter_checkin_sdk/flutter_checkin_sdk.dart';

final sdk = FlutterCheckinSdk();

Future<void> runCheckinFlow() async {
  await sdk.initialize();

  sdk.events.listen((event) {
    switch (event) {
      case VerificationStarted():
        print('Flow started');
      case VerificationCompleted(:final result):
        print('Completed: ${result.applicationId}');
      case VerificationCancelled():
        print('Cancelled');
      case VerificationFailed(:final error):
        print('Failed: ${error.message}');
      default:
        break;
    }
  });

  await sdk.startVerification(
    apiUrl: 'https://company-name.getid.ee',
    auth: CheckinAuth.sdkKey('YOUR_SDK_KEY'), // use JWT in production
    flowName: 'YOUR_FLOW_NAME',
    locale: 'en',
    metadata: const VerificationMetadata(
      externalId: 'user-123',
      labels: {'department': 'EST'},
    ),
    profileData: const {
      'first-name': 'John',
      'last-name': 'Doe',
    },
    acceptableDocuments: const AcceptableDocuments({
      'EST': [DocumentType.passport, DocumentType.idCard],
      'default': [DocumentType.passport],
    }),
  );
}
```

### JWT authentication (production)

Obtain a JWT from your backend using your SDK key:

```bash
curl -H "Content-Type: application/json" \
     -H "x-sdk-key: SDK_KEY" \
     -X POST API_URL/sdk/v2/token
```

Then pass the token:

```dart
await sdk.startVerification(
  apiUrl: apiUrl,
  auth: CheckinAuth.jwt(jwtToken),
  flowName: flowName,
);
```

### Verification results

The native SDK does **not** return verification results. Use the `applicationId` from [VerificationCompleted] and fetch results from your backend via the [Checkin.com API](https://dev.checkin.com/docs/verification-results).

## API reference

### `FlutterCheckinSdk`

| Method / property | Description |
|-------------------|-------------|
| `initialize()` | Prepares the plugin bridge |
| `startVerification(...)` | Starts `GetIDSDK.startVerificationFlow()` |
| `cancel()` | **TODO:** Not documented in Checkin SDK |
| `events` | Stream of `VerificationEvent` |

### Events (documented native callbacks)

| Dart event | Native callback |
|------------|-----------------|
| `VerificationStarted` | `verificationFlowStart()` / `verificationFlowDidStart()` |
| `VerificationCompleted` | `verificationFlowComplete()` / `verificationFlowDidComplete(_:)` |
| `VerificationCancelled` | `verificationFlowCancel()` / `verificationFlowDidCancel()` |
| `VerificationFailed` | `verificationFlowFail()` / `verificationFlowDidFail(_:)` |

The following event types exist in the Dart API but are **not** emitted by the current native SDK:

- `DocumentUploaded`
- `FaceScanStarted`
- `FaceScanCompleted`
- `Timeout`
- `SdkClosed`

### Exceptions

All platform errors are mapped to `CheckinException` subtypes:

- `InitializationException`
- `VerificationException`
- `CameraPermissionDenied`
- `NetworkException`
- `InvalidConfiguration`
- `SessionExpired`
- `UnsupportedCheckinException`
- `UnknownCheckinException`

## Architecture

```
Flutter app
    ↓
FlutterCheckinSdk (public API)
    ↓
CheckinRepository
    ↓
CheckinPlatform / MethodChannelCheckinPlatform
    ↓
MethodChannel + EventChannel
    ↓
Native GetID SDK (Android / iOS)
```

## Example app

```bash
cd example
flutter pub get
flutter run
```

Configure your `API URL`, `SDK key` or `JWT`, and `flow name` in the example UI.

## Troubleshooting

| Issue | Suggestion |
|-------|------------|
| `FLOW_NOT_FOUND` / `flowNotFound` | Verify the flow name in your Checkin.com Dashboard |
| `INVALID_KEY` / `invalidKey` | Use the SDK key, not the API key, in the mobile app |
| `DENY_PERMISSION` | Add camera permission descriptions and request runtime permission |
| `TOKEN_EXPIRED` | Fetch a fresh JWT from your backend |
| iOS build issues with User Script Sandboxing | Disable **User Script Sandboxing** in Xcode build settings (per Checkin.com docs) |
| Android dependency resolution fails | Add the GetID Maven CDN and JitPack repositories |
| Jetifier / `bcprov-jdk18on` build error | Set `android.enableJetifier=false` and add `bcprov-jdk18on` to `android.jetifier.ignorelist` in `gradle.properties` |
| `mergeDebugJavaResource` / duplicate `META-INF` | Add the `packaging.resources.excludes` block in `android/app/build.gradle` (see Android installation above) |

## Documentation

- [Android SDK](https://dev.checkin.com/docs/getid-native-sdk-1)
- [iOS SDK](https://dev.checkin.com/docs/getid-ios-sdk)
- [SDK Settings](https://dev.checkin.com/docs/getid-settings)
- [Verification Results](https://dev.checkin.com/docs/verification-results)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

Copyright (c) 2026 ahmed abdallah
