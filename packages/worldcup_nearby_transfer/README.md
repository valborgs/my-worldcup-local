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

The received platform file is copied into an app-owned temporary directory
before its real path is emitted to Dart. Canceling, leaving the transfer screen,
or detaching the host activity stops discovery/advertising, disconnects peers,
and removes plugin-owned temporary files.
