#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_checkin_sdk'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for the Checkin.com (GetID) native SDK.'
  s.description      = <<-DESC
Flutter plugin wrapping the Checkin.com native SDK for identity verification on Android and iOS.
                       DESC
  s.homepage         = 'https://dev.checkin.com/docs/getid-ios-sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Checkin.com' => 'support@checkin.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_checkin_sdk/Sources/flutter_checkin_sdk/**/*.swift'
  s.resource_bundles = {
    'flutter_checkin_sdk_privacy' => [
      'flutter_checkin_sdk/Sources/flutter_checkin_sdk/PrivacyInfo.xcprivacy'
    ]
  }
  s.dependency 'Flutter'
  # GetID is distributed via CDN podspec (not CocoaPods trunk). The host app
  # Podfile must also declare:
  #   pod 'GetID', :podspec => 'https://cdn.getid.cloud/sdk/ios/4.1.3/GetID.podspec'
  s.dependency 'GetID'
  s.platform = :ios, '13.0'
  s.swift_version = '5.7'
  # Required because GetID pulls RecaptchaEnterprise as static binaries.
  s.static_framework = true

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
