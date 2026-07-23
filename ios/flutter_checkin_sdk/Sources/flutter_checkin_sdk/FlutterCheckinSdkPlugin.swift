import Flutter
import GetID
import UIKit

public class FlutterCheckinSdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, GetIDSDKDelegate {
  private var eventSink: FlutterEventSink?
  private let mainQueue = DispatchQueue.main

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FlutterCheckinSdkPlugin()

    let methodChannel = FlutterMethodChannel(
      name: "flutter_checkin_sdk",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: "flutter_checkin_sdk/events",
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      result(nil)
    case "startVerification":
      startVerification(arguments: call.arguments, result: result)
    case "cancel":
      result(
        FlutterError(
          code: "UNSUPPORTED",
          message: "cancel() is not documented in the Checkin.com native SDK.",
          details: nil
        )
      )
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func startVerification(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any] else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Verification arguments are required.",
          details: nil
        )
      )
      return
    }

    guard
      let apiUrl = args["apiUrl"] as? String, !apiUrl.isEmpty,
      let flowName = args["flowName"] as? String, !flowName.isEmpty,
      let auth = args["auth"] as? [String: Any],
      let authType = auth["type"] as? String,
      let authValue = auth["value"] as? String,
      !authValue.isEmpty
    else {
      result(
        FlutterError(
          code: "INVALID_CONFIGURATION",
          message: "apiUrl, flowName, and auth are required.",
          details: nil
        )
      )
      return
    }

    let locale = args["locale"] as? String
    let dictionary = args["dictionary"] as? String
    let profileData = args["profileData"] as? [String: String]
    let metadata = args["metadata"] as? [String: Any]
    let acceptableDocuments = args["acceptableDocuments"] as? [String: Any]
    let customerId = metadata?["customerId"] as? String

    let nativeAuth: GetIDAuth
    switch authType {
    case "sdkKey":
      nativeAuth = .sdkKey(authValue, customerId: customerId)
    case "jwt":
      nativeAuth = .jwt(authValue)
    default:
      result(
        FlutterError(
          code: "INVALID_CONFIGURATION",
          message: "Unsupported auth type: \(authType)",
          details: nil
        )
      )
      return
    }

    mainQueue.async {
      GetIDSDK.delegate = self
      GetIDSDK.startVerificationFlow(
        apiUrl: apiUrl,
        auth: nativeAuth,
        flowName: flowName,
        profileData: Self.buildProfileData(profileData),
        acceptableDocuments: Self.buildAcceptableDocuments(acceptableDocuments),
        metadata: Self.buildMetadata(metadata),
        locale: locale,
        dictionary: dictionary
      )
      result(nil)
    }
  }

  private static func buildProfileData(_ raw: [String: String]?) -> GetIDProfileData? {
    guard let raw, !raw.isEmpty else { return nil }
    return GetIDProfileData(raw)
  }

  private static func buildMetadata(_ raw: [String: Any]?) -> GetIDMetadata? {
    guard let raw else { return nil }

    let externalId = raw["externalId"] as? String
    let labels = raw["labels"] as? [String: String]

    if externalId == nil, labels == nil || labels?.isEmpty == true {
      return nil
    }

    return GetIDMetadata(externalId: externalId, labels: labels)
  }

  private static func buildAcceptableDocuments(_ raw: [String: Any]?) -> GetIDAcceptableDocuments? {
    guard let raw, !raw.isEmpty else { return nil }

    var documentsByCountry: [GetIDAcceptableDocuments.Country: [GetIDDocumentType]] = [:]

    for (countryCode, value) in raw {
      guard let documentValues = value as? [String] else {
        continue
      }

      let country: GetIDAcceptableDocuments.Country =
        countryCode == "default" ? .default : GetIDAcceptableDocuments.Country(stringLiteral: countryCode)

      let mappedDocuments = documentValues.compactMap { document -> GetIDDocumentType? in
        switch document {
        case "passport":
          return .passport
        case "idCard":
          return .idCard
        case "residencePermit":
          return .residencePermit
        case "drivingLicence":
          return .drivingLicence
        case "voterCard":
          return .voterCard
        case "taxCard":
          return .taxCard
        case "addressCard":
          return .addressCard
        case "domesticPassport":
          return .domesticPassport
        case "studentCard":
          return .studentCard
        default:
          return GetIDDocumentType(rawValue: document)
        }
      }

      documentsByCountry[country] = mappedDocuments
    }

    return documentsByCountry.isEmpty ? nil : GetIDAcceptableDocuments(documentsByCountry)
  }

  private func emitEvent(_ payload: [String: Any]) {
    mainQueue.async {
      self.eventSink?(payload)
    }
  }

  public func verificationFlowStart() {
    emitEvent(["type": "verificationStarted"])
  }

  public func verificationFlowDidCancel() {
    emitEvent(["type": "verificationCancelled"])
  }

  public func verificationFlowDidFail(_ error: GetIDError) {
    emitEvent(
      [
        "type": "verificationFailed",
        "error": [
          "code": String(describing: error),
          "message": error.localizedDescription,
          "nativeError": String(describing: error),
        ],
      ]
    )
  }

  public func verificationFlowDidComplete(_ application: GetIDApplication) {
    emitEvent(
      [
        "type": "verificationCompleted",
        "result": [
          "applicationId": application.applicationId,
        ],
      ]
    )
  }
}
