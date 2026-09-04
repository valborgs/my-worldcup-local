# worldcup_nearby_transfer

Project-local Flutter plugin that transports one `.myworldcup` file to one
nearby device. It uses versioned `MethodChannel`/`EventChannel` messages and
does not depend on a community Nearby Flutter plugin.

- Android: Google Play services Nearby Connections `19.5.0`
- iOS: `google/nearby` pinned to revision
  `6d0ab62bb9e27cadac4a285ac46f886f293db2e1`
- Topology: Point-to-Point on both platforms
- Service ID: supplied by `NearbyProtocol.serviceId` on every native request
- iOS minimum: 13.0, required by the official Swift package

The iOS implementation is Swift Package Manager-only and intentionally has no
CocoaPods podspec because Google Nearby Connections for Swift is distributed as
a Swift package. Flutter 3.44 and later enable Swift Package Manager by default.
On older supported Flutter releases, enable it before building on macOS:

```shell
flutter config --enable-swift-package-manager
flutter pub get
```

The committed Runner Xcode project and scheme contain the generated Flutter
Swift package integration. A CocoaPods-only build is not supported by this
project-local plugin.

The received platform file is copied into an app-owned temporary directory
before its real path is emitted to Dart. Canceling, leaving the transfer screen,
or detaching the host activity stops discovery/advertising, disconnects peers,
and removes plugin-owned temporary files.
