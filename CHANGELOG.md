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
