import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_nearby_transfer/worldcup_nearby_transfer.dart';

void main() {
  test('플랫폼 채널 이벤트를 타입이 분명한 모델로 변환한다', () {
    final found = NearbyEvent.fromMap({
      'version': NearbyProtocol.version,
      'type': 'endpointFound',
      'endpointId': 'endpoint-1',
      'endpointName': 'Pixel',
    });
    final progress = NearbyEvent.fromMap({
      'version': NearbyProtocol.version,
      'type': 'transferProgress',
      'endpointId': 'endpoint-1',
      'payloadId': '42',
      'direction': 'receiving',
      'status': 'inProgress',
      'bytesTransferred': 25,
      'totalBytes': 100,
    });
    final received = NearbyEvent.fromMap({
      'version': NearbyProtocol.version,
      'type': 'fileReceived',
      'endpointId': 'endpoint-1',
      'payloadId': '42',
      'path': '/tmp/received.myworldcup',
      'name': '받은 월드컵.myworldcup',
      'size': 100,
    });

    expect(found, isA<NearbyEndpointFound>());
    expect((found as NearbyEndpointFound).endpoint.name, 'Pixel');
    expect(progress, isA<NearbyTransferProgress>());
    expect((progress as NearbyTransferProgress).fraction, .25);
    expect(received, isA<NearbyFileReceived>());
    expect((received as NearbyFileReceived).size, 100);
  });

  test('알 수 없는 프로토콜 버전과 이벤트는 거절한다', () {
    expect(
      () => NearbyEvent.fromMap({
        'version': 999,
        'type': 'endpointLost',
        'endpointId': 'endpoint-1',
      }),
      throwsA(isA<NearbyProtocolException>()),
    );
    expect(
      () => NearbyEvent.fromMap({
        'version': NearbyProtocol.version,
        'type': 'futureEvent',
      }),
      throwsA(isA<NearbyProtocolException>()),
    );
  });

  test('공통 serviceId의 SHA-256 Bonjour 타입이 iOS 설정과 일치한다', () {
    final hash = sha256.convert(utf8.encode(NearbyProtocol.serviceId)).bytes;
    final prefix = hash
        .take(12)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    final expected = '_$prefix._tcp';
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(NearbyProtocol.bonjourServiceType, expected);
    expect(plist, contains('<string>$expected</string>'));
  });

  test('Android와 iOS 네이티브 구현이 공통 serviceId와 Point-to-Point를 사용한다', () {
    final android = File(
      'packages/worldcup_nearby_transfer/android/src/main/kotlin/'
      'org/comon/worldcup_nearby_transfer/WorldcupNearbyTransferPlugin.kt',
    ).readAsStringSync();
    final ios = File(
      'packages/worldcup_nearby_transfer/ios/worldcup_nearby_transfer/Sources/'
      'worldcup_nearby_transfer/WorldcupNearbyTransferPlugin.swift',
    ).readAsStringSync();

    expect(android, contains('Strategy.P2P_POINT_TO_POINT'));
    expect(ios, contains('strategy: .pointToPoint'));
    expect(android, isNot(contains(NearbyProtocol.serviceId)));
    expect(ios, isNot(contains(NearbyProtocol.serviceId)));
    expect(android, contains('args?.get("serviceId")'));
    expect(ios, contains('arguments["serviceId"]'));
  });

  test('파일과 메타데이터가 어떤 순서로 도착해도 원본 payload ID로 완료 처리한다', () {
    final android = File(
      'packages/worldcup_nearby_transfer/android/src/main/kotlin/'
      'org/comon/worldcup_nearby_transfer/WorldcupNearbyTransferPlugin.kt',
    ).readAsStringSync();
    final ios = File(
      'packages/worldcup_nearby_transfer/ios/worldcup_nearby_transfer/Sources/'
      'worldcup_nearby_transfer/WorldcupNearbyTransferPlugin.swift',
    ).readAsStringSync();

    expect(android, contains('tryFinalizeIncoming(endpointId, filePayloadId)'));
    expect(android, contains('tryFinalizeIncoming(endpointId, payload.id)'));
    expect(ios, contains('incomingMetadata[payloadID] = metadata'));
    expect(ios, contains('finalizeIncoming(payloadID: payloadID)'));
  });

  test('Android 16에서도 Wi-Fi 상태 권한을 유지하고 상세 오류는 로그에만 기록한다', () {
    final manifest = File(
      'packages/worldcup_nearby_transfer/android/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final android = File(
      'packages/worldcup_nearby_transfer/android/src/main/kotlin/'
      'org/comon/worldcup_nearby_transfer/WorldcupNearbyTransferPlugin.kt',
    ).readAsStringSync();

    expect(
      manifest,
      contains(
        '<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />',
      ),
    );
    expect(
      manifest,
      contains(
        '<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />',
      ),
    );
    expect(
      manifest,
      isNot(contains('ACCESS_WIFI_STATE" android:maxSdkVersion')),
    );
    expect(android, contains('ConnectionsStatusCodes.getStatusCodeString'));
    expect(android, contains('Log.w('));
    expect(android,
        contains('result.error(\n            code,\n            message,'));
  });
}
