import CoreBluetooth
import Flutter
import NearbyConnections
import UIKit

public final class WorldcupNearbyTransferPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let protocolVersion = 1
  private static let methods = "org.comon.my_worldcup_local/nearby_transfer/methods"
  private static let events = "org.comon.my_worldcup_local/nearby_transfer/events"

  private var eventSink: FlutterEventSink?
  private var serviceID: String?
  private var connectionManager: ConnectionManager?
  private var advertiser: Advertiser?
  private var discoverer: Discoverer?
  private var bluetoothManager: CBCentralManager?
  private var isAdvertising = false
  private var isDiscovering = false
  private var pendingEndpointID: EndpointID?
  private var connectedEndpointID: EndpointID?
  private var endpointNames: [EndpointID: String] = [:]
  private var invitationHandlers: [EndpointID: (Bool) -> Void] = [:]
  private var verificationHandlers: [EndpointID: (Bool) -> Void] = [:]
  private var outgoingPayloadID: PayloadID?
  private var outgoingCancellationToken: CancellationToken?
  private var incomingResources: [PayloadID: IncomingResource] = [:]
  private var incomingMetadata: [PayloadID: FileMetadata] = [:]
  private var completedIncoming: Set<PayloadID> = []

  private struct IncomingResource {
    let endpointID: EndpointID
    let url: URL
    let fallbackName: String
    let cancellationToken: CancellationToken
  }

  private struct FileMetadata: Decodable {
    let version: Int
    let kind: String
    let payloadId: String
    let name: String
    let size: Int64
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = WorldcupNearbyTransferPlugin()
    let methodChannel = FlutterMethodChannel(name: methods, binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: events, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    cleanup(deleteReceivedFiles: true)
    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = validatedArguments(call.arguments, result: result) else { return }
    switch call.method {
    case "checkAvailability":
      result(availability())
    case "requestPermissions":
      requestPermissions(result: result)
    case "openAppSettings":
      openAppSettings(result: result)
    case "startDiscovery":
      startDiscovery(arguments: arguments, result: result)
    case "stopDiscovery":
      stopDiscovery()
      result(nil)
    case "startAdvertising":
      startAdvertising(arguments: arguments, result: result)
    case "stopAdvertising":
      stopAdvertising()
      result(nil)
    case "requestConnection":
      requestConnection(arguments: arguments, result: result)
    case "acceptConnection":
      respondToConnection(arguments: arguments, accept: true, result: result)
    case "rejectConnection":
      respondToConnection(arguments: arguments, accept: false, result: result)
    case "sendFile":
      sendFile(arguments: arguments, result: result)
    case "cancelTransfer":
      cancelTransfer()
      result(nil)
    case "disconnect":
      disconnect()
      result(nil)
    case "dispose":
      cleanup(deleteReceivedFiles: true)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func validatedArguments(
    _ value: Any?,
    result: @escaping FlutterResult
  ) -> [String: Any]? {
    guard
      let arguments = value as? [String: Any],
      arguments["version"] as? Int == Self.protocolVersion,
      let requestedServiceID = arguments["serviceId"] as? String,
      !requestedServiceID.isEmpty
    else {
      result(FlutterError(code: "protocol", message: "지원하지 않는 Nearby 프로토콜입니다.", details: nil))
      return nil
    }
    if let serviceID, serviceID != requestedServiceID {
      result(FlutterError(code: "protocol", message: "Nearby serviceId가 실행 중에 변경되었습니다.", details: nil))
      return nil
    }
    serviceID = requestedServiceID
    return arguments
  }

  private func requiredString(
    _ arguments: [String: Any],
    key: String,
    result: @escaping FlutterResult
  ) -> String? {
    guard let value = arguments[key] as? String, !value.isEmpty else {
      result(FlutterError(code: "protocol", message: "Nearby 요청의 \(key) 값이 없습니다.", details: nil))
      return nil
    }
    return value
  }

  private func ensureSession() -> Bool {
    if connectionManager != nil { return true }
    guard let serviceID else { return false }
    let manager = ConnectionManager(serviceID: serviceID, strategy: .pointToPoint)
    manager.delegate = self
    connectionManager = manager
    let advertiser = Advertiser(connectionManager: manager)
    advertiser.delegate = self
    self.advertiser = advertiser
    let discoverer = Discoverer(connectionManager: manager)
    discoverer.delegate = self
    self.discoverer = discoverer
    return true
  }

  private func permissionState() -> String {
    if #available(iOS 13.1, *) {
      switch CBCentralManager.authorization {
      case .denied, .restricted:
        return "permanentlyDenied"
      case .allowedAlways:
        return "granted"
      case .notDetermined:
        return "unknown"
      @unknown default:
        return "unknown"
      }
    }
    return "unknown"
  }

  private func bluetoothState() -> String {
    guard let bluetoothManager else { return "unknown" }
    switch bluetoothManager.state {
    case .poweredOn:
      return "enabled"
    case .poweredOff:
      return "disabled"
    case .unsupported:
      return "unavailable"
    default:
      return "unknown"
    }
  }

  private func availability() -> [String: Any] {
    #if targetEnvironment(simulator)
      let supported = false
      let message: Any = "Nearby Connections는 iOS 실제 기기에서만 사용할 수 있습니다."
    #else
      let supported = true
      let message: Any = NSNull()
    #endif
    return [
      "version": Self.protocolVersion,
      "supported": supported,
      "permission": permissionState(),
      "bluetooth": bluetoothState(),
      // iOS has no public synchronous API for the local-network permission or Wi-Fi radio.
      "wifi": "unknown",
      "canOpenSettings": true,
      "message": message,
    ]
  }

  private func requestPermissions(result: @escaping FlutterResult) {
    if bluetoothManager == nil {
      bluetoothManager = CBCentralManager(delegate: self, queue: .main)
    }
    // The local-network prompt is intentionally triggered only when the user starts
    // advertising/discovery through Nearby; iOS does not expose a standalone request API.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      result(self?.availability())
    }
  }

  private func openAppSettings(result: @escaping FlutterResult) {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      result(FlutterError(code: "unavailable", message: "앱 설정을 열 수 없습니다.", details: nil))
      return
    }
    UIApplication.shared.open(url, options: [:]) { opened in
      if opened {
        result(nil)
      } else {
        result(FlutterError(code: "unavailable", message: "앱 설정을 열 수 없습니다.", details: nil))
      }
    }
  }

  private func canStart(result: @escaping FlutterResult) -> Bool {
    #if targetEnvironment(simulator)
      result(FlutterError(code: "unavailable", message: "Nearby Connections는 iOS 실제 기기에서만 사용할 수 있습니다.", details: nil))
      return false
    #else
      if permissionState() == "permanentlyDenied" {
        result(FlutterError(code: "permissionPermanentlyDenied", message: "Bluetooth 권한을 앱 설정에서 허용해주세요.", details: nil))
        return false
      }
      if bluetoothState() == "disabled" {
        result(FlutterError(code: "radioOff", message: "Bluetooth와 Wi-Fi를 켜주세요.", details: nil))
        return false
      }
      guard ensureSession() else {
        result(FlutterError(code: "protocol", message: "Nearby 연결을 초기화할 수 없습니다.", details: nil))
        return false
      }
      return true
    #endif
  }

  private func startDiscovery(arguments: [String: Any], result: @escaping FlutterResult) {
    guard canStart(result: result) else { return }
    guard !isAdvertising, !isDiscovering, pendingEndpointID == nil, connectedEndpointID == nil else {
      result(FlutterError(code: "alreadyBusy", message: "이미 다른 Nearby 작업이 진행 중입니다.", details: nil))
      return
    }
    isDiscovering = true
    discoverer?.startDiscovery { [weak self] error in
      if let error {
        self?.isDiscovering = false
        result(self?.flutterError(code: "unavailable", message: "주변 기기 검색을 시작할 수 없습니다.", error: error))
      } else {
        result(nil)
      }
    }
  }

  private func startAdvertising(arguments: [String: Any], result: @escaping FlutterResult) {
    guard canStart(result: result) else { return }
    guard !isAdvertising, !isDiscovering, pendingEndpointID == nil, connectedEndpointID == nil else {
      result(FlutterError(code: "alreadyBusy", message: "이미 다른 Nearby 작업이 진행 중입니다.", details: nil))
      return
    }
    guard let displayName = requiredString(arguments, key: "displayName", result: result),
          let context = displayName.data(using: .utf8) else { return }
    isAdvertising = true
    advertiser?.startAdvertising(using: context) { [weak self] error in
      if let error {
        self?.isAdvertising = false
        result(self?.flutterError(code: "unavailable", message: "수신 대기를 시작할 수 없습니다.", error: error))
      } else {
        result(nil)
      }
    }
  }

  private func stopDiscovery() {
    if isDiscovering { discoverer?.stopDiscovery() }
    isDiscovering = false
  }

  private func stopAdvertising() {
    if isAdvertising { advertiser?.stopAdvertising() }
    isAdvertising = false
  }

  private func requestConnection(arguments: [String: Any], result: @escaping FlutterResult) {
    guard isDiscovering, pendingEndpointID == nil, connectedEndpointID == nil else {
      result(FlutterError(code: "invalidState", message: "연결 요청을 시작할 수 없는 상태입니다.", details: nil))
      return
    }
    guard let endpointID = requiredString(arguments, key: "endpointId", result: result),
          let displayName = requiredString(arguments, key: "displayName", result: result),
          let context = displayName.data(using: .utf8) else { return }
    guard endpointNames[endpointID] != nil else {
      result(FlutterError(code: "invalidState", message: "선택한 기기를 더 이상 찾을 수 없습니다.", details: nil))
      return
    }
    pendingEndpointID = endpointID
    discoverer?.requestConnection(to: endpointID, using: context) { [weak self] error in
      if let error {
        self?.pendingEndpointID = nil
        result(self?.flutterError(code: "connectionFailed", message: "연결 요청을 보낼 수 없습니다.", error: error))
      } else {
        self?.stopDiscovery()
        result(nil)
      }
    }
  }

  private func respondToConnection(
    arguments: [String: Any],
    accept: Bool,
    result: @escaping FlutterResult
  ) {
    guard let endpointID = requiredString(arguments, key: "endpointId", result: result) else { return }
    if let handler = invitationHandlers.removeValue(forKey: endpointID) {
      if !accept { pendingEndpointID = nil }
      handler(accept)
      result(nil)
      return
    }
    if let handler = verificationHandlers.removeValue(forKey: endpointID) {
      if !accept { pendingEndpointID = nil }
      handler(accept)
      result(nil)
      return
    }
    result(FlutterError(code: "invalidState", message: "대기 중인 연결 확인이 없습니다.", details: nil))
  }

  private func sendFile(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let endpointID = requiredString(arguments, key: "endpointId", result: result),
          let path = requiredString(arguments, key: "path", result: result),
          let requestedName = requiredString(arguments, key: "name", result: result) else { return }
    guard connectedEndpointID == endpointID, outgoingPayloadID == nil else {
      result(FlutterError(code: "alreadyBusy", message: "한 번에 하나의 파일만 전송할 수 있습니다.", details: nil))
      return
    }
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.isReadableFile(atPath: url.path),
          let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
          let size = attributes[.size] as? NSNumber else {
      result(FlutterError(code: "io", message: "전송할 월드컵 파일을 읽을 수 없습니다.", details: nil))
      return
    }
    let payloadID = Int64.random(in: 1...Int64.max)
    let safeName = sanitizeName(requestedName)
    let metadata: [String: Any] = [
      "version": Self.protocolVersion,
      "kind": "fileMetadata",
      "payloadId": String(payloadID),
      "name": safeName,
      "size": size.int64Value,
    ]
    guard let metadataData = try? JSONSerialization.data(withJSONObject: metadata) else {
      result(FlutterError(code: "protocol", message: "파일 메타데이터를 만들 수 없습니다.", details: nil))
      return
    }
    outgoingPayloadID = payloadID
    _ = connectionManager?.send(metadataData, to: [endpointID]) { [weak self] error in
      guard let error else { return }
      self?.outgoingPayloadID = nil
      self?.emitError(code: "transferFailed", message: "파일 정보를 전송하지 못했습니다.", recoverable: false)
    }
    outgoingCancellationToken = connectionManager?.sendResource(
      at: url,
      withName: safeName,
      to: [endpointID],
      id: payloadID
    ) { [weak self] error in
      if let error {
        self?.outgoingPayloadID = nil
        result(self?.flutterError(code: "transferFailed", message: "파일 전송을 시작할 수 없습니다.", error: error))
      } else {
        result(nil)
      }
    }
  }

  private func cancelTransfer() {
    outgoingCancellationToken?.cancel()
    outgoingCancellationToken = nil
    outgoingPayloadID = nil
    incomingResources.values.forEach { $0.cancellationToken.cancel() }
  }

  private func disconnect() {
    if let endpointID = connectedEndpointID ?? pendingEndpointID {
      connectionManager?.disconnect(from: endpointID)
    }
    connectedEndpointID = nil
    pendingEndpointID = nil
  }

  private func cleanup(deleteReceivedFiles: Bool) {
    cancelTransfer()
    stopDiscovery()
    stopAdvertising()
    disconnect()
    invitationHandlers.values.forEach { $0(false) }
    verificationHandlers.values.forEach { $0(false) }
    invitationHandlers.removeAll()
    verificationHandlers.removeAll()
    incomingResources.removeAll()
    incomingMetadata.removeAll()
    completedIncoming.removeAll()
    endpointNames.removeAll()
    connectionManager = nil
    advertiser = nil
    discoverer = nil
    serviceID = nil
    if deleteReceivedFiles {
      let directory = transferDirectory()
      if directory.path.hasPrefix(FileManager.default.temporaryDirectory.path) {
        try? FileManager.default.removeItem(at: directory)
      }
    }
  }

  private func transferDirectory() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(
      "nearby_worldcup_transfer",
      isDirectory: true
    )
  }

  private func finalizeIncoming(payloadID: PayloadID) {
    guard let resource = incomingResources[payloadID],
          let metadata = incomingMetadata[payloadID],
          completedIncoming.contains(payloadID) else { return }
    incomingResources.removeValue(forKey: payloadID)
    incomingMetadata.removeValue(forKey: payloadID)
    completedIncoming.remove(payloadID)
    let directory = transferDirectory()
    let destination = directory.appendingPathComponent("\(UUID().uuidString).myworldcup")
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: resource.url, to: destination)
        let attributes = try FileManager.default.attributesOfItem(atPath: destination.path)
        let actualSize = (attributes[.size] as? NSNumber)?.int64Value ?? -1
        guard actualSize == metadata.size else {
          try? FileManager.default.removeItem(at: destination)
          self.emitError(code: "io", message: "수신 파일의 크기를 확인할 수 없습니다.", recoverable: false)
          return
        }
        self.emit(
          type: "fileReceived",
          values: [
            "endpointId": resource.endpointID,
            "payloadId": String(payloadID),
            "path": destination.path,
            "name": self.sanitizeName(metadata.name),
            "size": actualSize,
          ]
        )
      } catch {
        try? FileManager.default.removeItem(at: destination)
        self.emitError(code: "io", message: "수신 파일을 임시 저장소에 복사하지 못했습니다.", recoverable: false)
      }
    }
  }

  private func parseMetadata(_ data: Data) {
    guard let metadata = try? JSONDecoder().decode(FileMetadata.self, from: data),
          metadata.version == Self.protocolVersion,
          metadata.kind == "fileMetadata",
          let payloadID = Int64(metadata.payloadId),
          metadata.size >= 0 else {
      emitError(code: "protocol", message: "파일 메타데이터가 올바르지 않습니다.", recoverable: false)
      return
    }
    incomingMetadata[payloadID] = metadata
    finalizeIncoming(payloadID: payloadID)
  }

  private func sanitizeName(_ name: String) -> String {
    let leaf = URL(fileURLWithPath: name).lastPathComponent
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._- "))
    let sanitized = String(leaf.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "_" })
      .prefix(100)
    let value = sanitized.isEmpty ? "worldcup.myworldcup" : String(sanitized)
    return value.lowercased().hasSuffix(".myworldcup") ? value : "\(value).myworldcup"
  }

  private func displayName(from context: Data, endpointID: EndpointID) -> String {
    let name = String(data: context, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    return name?.isEmpty == false ? name! : (endpointNames[endpointID] ?? "이름 없는 기기")
  }

  private func emit(type: String, values: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(["version": Self.protocolVersion, "type": type].merging(values) { _, new in new })
    }
  }

  private func emitConnection(endpointID: EndpointID, state: String) {
    emit(type: "connectionState", values: ["endpointId": endpointID, "state": state])
  }

  private func emitError(code: String, message: String, recoverable: Bool) {
    emit(type: "error", values: ["code": code, "message": message, "recoverable": recoverable])
  }

  private func flutterError(code: String, message: String, error: Error) -> FlutterError {
    FlutterError(code: code, message: message, details: error.localizedDescription)
  }
}

extension WorldcupNearbyTransferPlugin: CBCentralManagerDelegate {
  public func centralManagerDidUpdateState(_ central: CBCentralManager) {}
}

extension WorldcupNearbyTransferPlugin: AdvertiserDelegate {
  public func advertiser(
    _ advertiser: Advertiser,
    didReceiveConnectionRequestFrom endpointID: EndpointID,
    with context: Data,
    connectionRequestHandler: @escaping (Bool) -> Void
  ) {
    guard isAdvertising, pendingEndpointID == nil, connectedEndpointID == nil else {
      connectionRequestHandler(false)
      return
    }
    pendingEndpointID = endpointID
    let name = displayName(from: context, endpointID: endpointID)
    endpointNames[endpointID] = name
    invitationHandlers[endpointID] = connectionRequestHandler
    emit(
      type: "connectionRequest",
      values: ["endpointId": endpointID, "endpointName": name, "incoming": true]
    )
  }
}

extension WorldcupNearbyTransferPlugin: DiscovererDelegate {
  public func discoverer(
    _ discoverer: Discoverer,
    didFind endpointID: EndpointID,
    with context: Data
  ) {
    let name = displayName(from: context, endpointID: endpointID)
    endpointNames[endpointID] = name
    emit(type: "endpointFound", values: ["endpointId": endpointID, "endpointName": name])
  }

  public func discoverer(_ discoverer: Discoverer, didLose endpointID: EndpointID) {
    endpointNames.removeValue(forKey: endpointID)
    emit(type: "endpointLost", values: ["endpointId": endpointID])
  }
}

extension WorldcupNearbyTransferPlugin: ConnectionManagerDelegate {
  public func connectionManager(
    _ connectionManager: ConnectionManager,
    didReceive verificationCode: String,
    from endpointID: EndpointID,
    verificationHandler: @escaping (Bool) -> Void
  ) {
    verificationHandlers[endpointID] = verificationHandler
    let name = endpointNames[endpointID] ?? "이름 없는 기기"
    emit(
      type: "verificationCode",
      values: ["endpointId": endpointID, "endpointName": name, "code": verificationCode]
    )
  }

  public func connectionManager(
    _ connectionManager: ConnectionManager,
    didReceive data: Data,
    withID payloadID: PayloadID,
    from endpointID: EndpointID
  ) {
    parseMetadata(data)
  }

  public func connectionManager(
    _ connectionManager: ConnectionManager,
    didReceive stream: InputStream,
    withID payloadID: PayloadID,
    from endpointID: EndpointID,
    cancellationToken token: CancellationToken
  ) {
    token.cancel()
    emitError(code: "protocol", message: "지원하지 않는 스트림 payload입니다.", recoverable: false)
  }

  public func connectionManager(
    _ connectionManager: ConnectionManager,
    didStartReceivingResourceWithID payloadID: PayloadID,
    from endpointID: EndpointID,
    at localURL: URL,
    withName name: String,
    cancellationToken token: CancellationToken
  ) {
    incomingResources[payloadID] = IncomingResource(
      endpointID: endpointID,
      url: localURL,
      fallbackName: name,
      cancellationToken: token
    )
    finalizeIncoming(payloadID: payloadID)
  }

  public func connectionManager(
    _ connectionManager: ConnectionManager,
    didReceiveTransferUpdate update: TransferUpdate,
    from endpointID: EndpointID,
    forPayload payloadID: PayloadID
  ) {
    let isOutgoingFile = outgoingPayloadID == payloadID
    let isIncomingFile = incomingResources[payloadID] != nil
    guard isOutgoingFile || isIncomingFile else { return }
    let direction = isOutgoingFile ? "sending" : "receiving"
    var status = "inProgress"
    var transferred: Int64 = 0
    var total: Int64 = 0
    switch update {
    case .progress(let progress):
      transferred = progress.completedUnitCount
      total = progress.totalUnitCount
    case .success:
      status = "success"
      if direction == "sending" {
        outgoingPayloadID = nil
        outgoingCancellationToken = nil
      } else {
        completedIncoming.insert(payloadID)
      }
    case .canceled:
      status = "canceled"
      incomingResources.removeValue(forKey: payloadID)
      incomingMetadata.removeValue(forKey: payloadID)
      completedIncoming.remove(payloadID)
      if direction == "sending" { outgoingPayloadID = nil }
    case .failure:
      status = "failure"
      incomingResources.removeValue(forKey: payloadID)
      incomingMetadata.removeValue(forKey: payloadID)
      completedIncoming.remove(payloadID)
      if direction == "sending" { outgoingPayloadID = nil }
    }
    emit(
      type: "transferProgress",
      values: [
        "endpointId": endpointID,
        "payloadId": String(payloadID),
        "direction": direction,
        "status": status,
        "bytesTransferred": transferred,
        "totalBytes": total,
      ]
    )
    finalizeIncoming(payloadID: payloadID)
  }

  public func connectionManager(
    _ connectionManager: ConnectionManager,
    didChangeTo state: ConnectionState,
    for endpointID: EndpointID
  ) {
    switch state {
    case .connecting:
      emitConnection(endpointID: endpointID, state: "connecting")
    case .connected:
      connectedEndpointID = endpointID
      pendingEndpointID = nil
      stopDiscovery()
      stopAdvertising()
      emitConnection(endpointID: endpointID, state: "connected")
    case .rejected:
      pendingEndpointID = nil
      emitConnection(endpointID: endpointID, state: "rejected")
    case .disconnected:
      pendingEndpointID = nil
      connectedEndpointID = nil
      outgoingPayloadID = nil
      emitConnection(endpointID: endpointID, state: "disconnected")
    }
  }
}
