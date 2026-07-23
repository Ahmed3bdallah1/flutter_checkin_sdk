## 1.0.0

Major release: iOS native integration rewrite, Android release/R8 fix, and host-app install requirements.

### Breaking / host-app required changes (iOS)

* **CocoaPods:** GetID is no longer declared with an inline CDN `:podspec` URL inside this plugin’s podspec. The host app `ios/Podfile` must declare:
  `pod 'GetID', :podspec => 'https://cdn.getid.cloud/sdk/ios/4.1.3/GetID.podspec'`
  before `flutter_install_all_ios_pods`.
* **Linkage:** plugin podspec sets `s.static_framework = true` (GetID → RecaptchaEnterprise static binaries). Host apps should use `use_frameworks! :linkage => :static` (or equivalent static-framework handling).
* **Deployment target:** plugin package targets iOS **13.0+**; GetID native SDK requires the **app** deployment target **16.0+**.
* **Source layout:** removed `ios/Classes/FlutterCheckinSdkPlugin.swift` and `ios/Resources/PrivacyInfo.xcprivacy`. Sources now live under Swift Package layout:
  * `ios/flutter_checkin_sdk/Package.swift`
  * `ios/flutter_checkin_sdk/Sources/flutter_checkin_sdk/FlutterCheckinSdkPlugin.swift`
  * `ios/flutter_checkin_sdk/Sources/flutter_checkin_sdk/PrivacyInfo.xcprivacy`
* **Podspec `source_files`:** now `flutter_checkin_sdk/Sources/flutter_checkin_sdk/**/*.swift`.
* **Privacy manifest:** shipped via CocoaPods `resource_bundles` (`flutter_checkin_sdk_privacy`) and SPM `resources: [.process("PrivacyInfo.xcprivacy")]`.

### iOS native API / bridge

* Rewrote `FlutterCheckinSdkPlugin` for current GetID 4.1.3 Swift API:
  * Auth: `GetIDAuth` (`.sdkKey(_:customerId:)` / `.jwt(_:)`) instead of older `Auth` overloads.
  * Profile: `GetIDProfileData`.
  * Metadata: `GetIDMetadata(externalId:labels:)`.
  * Documents: `GetIDAcceptableDocuments` / `GetIDDocumentType` (passport, idCard, residencePermit, drivingLicence, voterCard, taxCard, addressCard, domesticPassport, studentCard, plus `rawValue` fallback).
* Single `GetIDSDK.startVerificationFlow(...)` call with optional profile/metadata/documents instead of combinatorial overload branches.
* Stream handler methods return `FlutterError?` (`onListen` / `onCancel`).
* Delegate start callback uses `verificationFlowStart()`.
* SDK key auth passes optional `customerId` from metadata when present.
* **Swift Package Manager:** `Package.swift` resolves GetID from [vvorld/getid-ios-sdk](https://github.com/vvorld/getid-ios-sdk) (`from: "4.1.3"`).

### Android

* Added `android/consumer-rules.pro` keep rules for GetID (`com.sdk.getidlib.**`, `ee.getid.**`), Gson, Retrofit, Moshi, OkHttp, and plugin bridge classes.
* Wired rules via `consumerProguardFiles "consumer-rules.pro"` in `android/build.gradle` so minify/R8 full-mode host apps pick them up automatically.
* Fixes release-only crash: `java.lang.Class cannot be cast to java.lang.reflect.ParameterizedType` (R8 stripping generic `Signature` attributes).
* Lint: `checkReleaseBuilds false`, `abortOnError false`, disable `NullSafeMutableLiveData`.

### Example app

* Added `example/ios/Podfile` with GetID CDN podspec, static frameworks, iOS 16.0 platform, `COPYFILE_DISABLE`, pod `CODE_SIGNING_ALLOWED=NO`, and GetID/Recaptcha xattr strip + ad-hoc re-sign for Simulator codesign issues.
* Raised example `IPHONEOS_DEPLOYMENT_TARGET` from `13.0` to `16.0`.

### Docs / packaging

* README: iOS SPM + CocoaPods install steps, static linkage, deployment-target note, R8/ProGuard section, troubleshooting for init and release `ParameterizedType` / Simulator codesign.
* Root `.gitignore`: ignore SwiftPM `.build/` and `.swiftpm/`.
* Version bumped to **1.0.0**.

## 0.1.4

* Register the default method channel via `FlutterCheckinSdk` factory constructor and early platform bootstrap before repository access.
* Add debug-only diagnostic logging (`logger` package) for initialize, startVerification, and verification events.

## 0.1.3

* Update GetID SDK to 4.1.3 for Android and 4.1.2 for iOS.
* Ensure Dart SDK 3.0 compatibility by updating `pubspec.yaml` and `analysis_options.yaml`.

## 0.1.2

* Fix Android build issues with `bcprov-jdk18on` by disabling Jetifier in `gradle.properties`.
* Fix ParseException when using `startVerification` with `GetIDConfig` on Android.

## 0.1.0

* Initial release wrapping Checkin.com GetID native SDK for Android and iOS.
* Exposes `startVerification`, event stream, typed models, and exceptions.
* Includes Riverpod example app.
