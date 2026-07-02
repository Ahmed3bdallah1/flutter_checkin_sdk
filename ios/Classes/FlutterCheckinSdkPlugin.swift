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

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) {
    eventSink = events
  }

  public func onCancel(withArguments arguments: Any?) {
    eventSink = nil
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

    mainQueue.async {
      GetIDSDK.delegate = self

      switch authType {
      case "sdkKey":
        self.invokeStartVerificationFlow(
          apiUrl: apiUrl,
          auth: .sdkKey(authValue),
          flowName: flowName,
          locale: locale,
          dictionary: dictionary,
          profileData: profileData,
          metadata: metadata,
          acceptableDocuments: acceptableDocuments
        )
      case "jwt":
        self.invokeStartVerificationFlow(
          apiUrl: apiUrl,
          auth: .jwt(authValue),
          flowName: flowName,
          locale: locale,
          dictionary: dictionary,
          profileData: profileData,
          metadata: metadata,
          acceptableDocuments: acceptableDocuments
        )
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

      result(nil)
    }
  }

  private func invokeStartVerificationFlow(
    apiUrl: String,
    auth: Auth,
    flowName: String,
    locale: String?,
    dictionary: String?,
    profileData: [String: String]?,
    metadata: [String: Any]?,
    acceptableDocuments: [String: Any]?
  ) {
    if let acceptableDocuments,
       let acceptable = buildAcceptableDocuments(acceptableDocuments) {
      if let metadata, let nativeMetadata = buildMetadata(metadata) {
        if let profileData, !profileData.isEmpty {
          GetIDSDK.startVerificationFlow(
            apiUrl: apiUrl,
            auth: auth,
            flowName: flowName,
            locale: locale,
            dictionary: dictionary,
            profileData: .init(profileData),
            metadata: nativeMetadata,
            acceptableDocuments: acceptable
          )
          return
        }

        GetIDSDK.startVerificationFlow(
          apiUrl: apiUrl,
          auth: auth,
          flowName: flowName,
          locale: locale,
          dictionary: dictionary,
          metadata: nativeMetadata,
          acceptableDocuments: acceptable
        )
        return
      }

      if let profileData, !profileData.isEmpty {
        GetIDSDK.startVerificationFlow(
          apiUrl: apiUrl,
          auth: auth,
          flowName: flowName,
          locale: locale,
          dictionary: dictionary,
          profileData: .init(profileData),
          acceptableDocuments: acceptable
        )
        return
      }

      GetIDSDK.startVerificationFlow(
        apiUrl: apiUrl,
        auth: auth,
        flowName: flowName,
        locale: locale,
        dictionary: dictionary,
        acceptableDocuments: acceptable
      )
      return
    }

    if let metadata, let nativeMetadata = buildMetadata(metadata) {
      if let profileData, !profileData.isEmpty {
        GetIDSDK.startVerificationFlow(
          apiUrl: apiUrl,
          auth: auth,
          flowName: flowName,
          locale: locale,
          dictionary: dictionary,
          profileData: .init(profileData),
          metadata: nativeMetadata
        )
        return
      }

      GetIDSDK.startVerificationFlow(
        apiUrl: apiUrl,
        auth: auth,
        flowName: flowName,
        locale: locale,
        dictionary: dictionary,
        metadata: nativeMetadata
      )
      return
    }

    if let profileData, !profileData.isEmpty {
      GetIDSDK.startVerificationFlow(
        apiUrl: apiUrl,
        auth: auth,
        flowName: flowName,
        locale: locale,
        dictionary: dictionary,
        profileData: .init(profileData)
      )
      return
    }

    GetIDSDK.startVerificationFlow(
      apiUrl: apiUrl,
      auth: auth,
      flowName: flowName,
      locale: locale,
      dictionary: dictionary
    )
  }

  private func buildMetadata(_ raw: [String: Any]) -> Metadata? {
    if let externalId = raw["externalId"] as? String {
      return .init(externalId: externalId)
    }

    if let labels = raw["labels"] as? [String: String], !labels.isEmpty {
      return .init(labels: labels)
    }

    // TODO: Not documented in Checkin SDK.
    // Combined metadata initializers for customerId plus labels are not shown in the docs.
    if let customerId = raw["customerId"] as? String {
      return .init(customerId: customerId)
    }

    return nil
  }

  private func buildAcceptableDocuments(_ raw: [String: Any]) -> AcceptableDocuments? {
    var documentsByCountry: [AcceptableDocuments.Country: [DocumentType]] = [:]

    for (countryCode, value) in raw {
      guard let documentValues = value as? [String] else {
        continue
      }

      let country: AcceptableDocuments.Country =
        countryCode == "default" ? .default : .custom(countryCode)

      let mappedDocuments = documentValues.compactMap { document -> DocumentType? in
        switch document {
        case "passport":
          return .passport
        case "idCard":
          return .idCard
        default:
          return nil
        }
      }

      documentsByCountry[country] = mappedDocuments
    }

    return documentsByCountry.isEmpty ? nil : .init(documentsByCountry)
  }

  private func emitEvent(_ payload: [String: Any]) {
    mainQueue.async {
      self.eventSink?(payload)
    }
  }

  public func verificationFlowDidStart() {
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
