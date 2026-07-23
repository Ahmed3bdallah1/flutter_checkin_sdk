// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "flutter_checkin_sdk",
  platforms: [
    .iOS("13.0"),
  ],
  products: [
    .library(name: "flutter-checkin-sdk", targets: ["flutter_checkin_sdk"]),
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    .package(url: "https://github.com/vvorld/getid-ios-sdk", from: "4.1.3"),
  ],
  targets: [
    .target(
      name: "flutter_checkin_sdk",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "GetID", package: "getid-ios-sdk"),
      ],
      resources: [
        .process("PrivacyInfo.xcprivacy"),
      ]
    ),
  ]
)
