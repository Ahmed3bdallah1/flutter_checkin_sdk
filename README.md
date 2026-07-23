# flutter_checkin_sdk

Production-ready Flutter plugin for the [Checkin.com (GetID) native SDK](https://dev.checkin.com/docs/getid-native-sdk-1) on Android and iOS.

## Features

- Clean Dart API with repository and platform interface layers
- `MethodChannel` for commands, `EventChannel` for SDK callbacks
- Strongly typed models, events, and exceptions
- Safe platform bootstrap: method channel is registered before repository access
- Debug-only diagnostic logging (`logger`) for initialize, startVerification, and events
- Android (Kotlin) and iOS (Swift) implementations
- Example app with Riverpod state management

## Supported platforms

| Platform | Minimum version | Native SDK |
|----------|-----------------|------------|
| Android  | API 21+         | `ee.getid:getidlib:4.2.2` |
| iOS      | 13.0+ (plugin) / 16.0+ (GetID SDK) | `GetID 4.1.3` |

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_checkin_sdk: ^1.0.0 # or pub.dev latest published version
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

#### Release / R8 (minify) builds

Release builds with R8 full mode (`android.enableR8.fullMode=true`, the Android Gradle Plugin default) can crash the GetID SDK with:

```text
java.lang.Class cannot be cast to java.lang.reflect.ParameterizedType
```

R8 strips generic `Signature` attributes that Retrofit/Gson/Moshi reflection needs. This plugin ships `android/consumer-rules.pro` and wires it via `consumerProguardFiles` in `android/build.gradle`, so host apps that enable minify automatically get the keep rules. No extra ProGuard config is required in the app unless you override consumer rules.

### iOS

The plugin supports both **Swift Package Manager** and **CocoaPods**.

The Flutter plugin package targets **iOS 13.0+**. The Checkin.com GetID native SDK itself requires **iOS 16.0+**, so set your app’s deployment target to 16.0 or higher.

#### Swift Package Manager

With Flutter’s SwiftPM integration enabled, GetID is resolved from [vvorld/getid-ios-sdk](https://github.com/vvorld/getid-ios-sdk) via the plugin’s `Package.swift`. No extra Podfile entry is required when using SPM for this plugin.

#### CocoaPods

GetID is not published on the CocoaPods trunk. Add this line to your app’s `ios/Podfile` (before `flutter_install_all_ios_pods`):

```ruby
pod 'GetID', :podspec => 'https://cdn.getid.cloud/sdk/ios/4.1.3/GetID.podspec'
```

Because GetID depends on RecaptchaEnterprise (static binaries), use static framework linkage:

```ruby
use_frameworks! :linkage => :static
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

Creating `FlutterCheckinSdk()` uses a factory constructor that calls `ensureCheckinPlatformRegistered()` **before** the repository reads `CheckinPlatform.instance`. That avoids unbound method-channel / missing-implementation failures when `initialize()` or `startVerification()` runs.

```dart
final sdk = FlutterCheckinSdk();
await sdk.initialize();
```

### Debug logging (0.1.4+)

In debug builds, the plugin logs initialize, startVerification, and verification events via the `logger` package (`checkinLogger`). Logging is off in release (`kDebugMode` only). No host-app setup is required.

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

  /// apiUrl, flowName, and SDK key are provided by your Checkin.com account
  /// In production, use JWT authentication instead of the SDK key.
  /// See the "JWT authentication" section below.
  /// If you are in the sandbox environment, use the sandbox API URL and flow name.
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
| `FlutterCheckinSdk()` | Factory: registers the default method channel, then creates the repository |
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
| Init / missing method channel / unbound handler | Use `FlutterCheckinSdk()` (factory) so the platform is registered before repository access; call `initialize()` before `startVerification`. Fixed in **0.1.4**. |
| `FLOW_NOT_FOUND` / `flowNotFound` | Verify the flow name in your Checkin.com Dashboard |
| `INVALID_KEY` / `invalidKey` | Use the SDK key, not the API key, in the mobile app |
| `DENY_PERMISSION` | Add camera permission descriptions and request runtime permission |
| `TOKEN_EXPIRED` | Fetch a fresh JWT from your backend |
| iOS build issues with User Script Sandboxing | Disable **User Script Sandboxing** in Xcode build settings (per Checkin.com docs) |
| CodeSign fails on Simulator (`resource fork, Finder information…`) | Common when the repo lives under iCloud-synced `~/Documents`. The app `Podfile` sets `CODE_SIGNING_ALLOWED=NO` on pod targets and re-signs GetID/Recaptcha. Prefer cloning outside iCloud if issues persist. |
| Android dependency resolution fails | Add the GetID Maven CDN and JitPack repositories |
| Jetifier / `bcprov-jdk18on` build error | Set `android.enableJetifier=false` and add `bcprov-jdk18on` to `android.jetifier.ignorelist` in `gradle.properties` |
| `mergeDebugJavaResource` / duplicate `META-INF` | Add the `packaging.resources.excludes` block in `android/app/build.gradle` (see Android installation above) |
| Release crash: `Class` cannot be cast to `ParameterizedType` | Caused by R8 full mode stripping generic signatures. Fixed by plugin `consumer-rules.pro` (auto-applied when minify is on). Rebuild the release app after upgrading the plugin. |

## Release notes (1.0.0)

See [CHANGELOG.md](CHANGELOG.md) for the full 1.0.0 list. Highlights:

- **iOS rewrite:** Swift Package source layout, `static_framework`, host Podfile must declare GetID CDN podspec, updated GetID 4.1.3 Swift types (`GetIDAuth`, `GetIDMetadata`, `GetIDAcceptableDocuments`, …).
- **Android release / R8:** `consumer-rules.pro` via `consumerProguardFiles` fixes minify `ParameterizedType` crash.
- **Example:** iOS 16.0 + Podfile GetID/Recaptcha codesign workarounds.

## Documentation

- [Android SDK](https://dev.checkin.com/docs/getid-native-sdk-1)
- [iOS SDK](https://dev.checkin.com/docs/getid-ios-sdk)
- [SDK Settings](https://dev.checkin.com/docs/getid-settings)
- [Verification Results](https://dev.checkin.com/docs/verification-results)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

Copyright (c) 2026 ahmed abdallah
