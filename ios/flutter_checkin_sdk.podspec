#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_checkin_sdk'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin for the Checkin.com (GetID) native SDK.'
  s.description      = <<-DESC
Flutter plugin wrapping the Checkin.com native SDK for identity verification on Android and iOS.
                       DESC
  s.homepage         = 'https://dev.checkin.com/docs/getid-ios-sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Checkin.com' => 'support@checkin.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'GetID', :podspec => 'https://cdn.getid.cloud/sdk/ios/4.1.3/GetID.podspec'
  s.platform = :ios, '16.0'
  s.swift_version = '5.7'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
