# worldcup_in_app_update

Google Play In-App Update를 감싸는 프로젝트 전용 플러그인이다. 버전이 붙은
`MethodChannel`/`EventChannel` 메시지를 쓰고, 커뮤니티 플러그인에 의존하지 않는다.

- 안드로이드: `com.google.android.play:app-update:2.1.0`
- 평소에는 **유연한(Flexible) 업데이트**만 쓴다. 앱 사용 흐름을 끊지 않는 것이
  이 기능의 목적이다.
- **즉시(Immediate) 업데이트**는 반드시 올려야 하는 버전에만 쓴다. 판단은 Dart
  쪽(Remote Config의 `minRequiredVersionCode`)이 하고, 플러그인은 요청받은
  흐름을 띄우기만 한다.
- iOS 구현은 없다. 인앱 업데이트는 Play 스토어 전용이라, `MethodChannelInAppUpdateGateway`가
  안드로이드가 아닌 플랫폼에서는 채널을 건드리지 않고 조용히 "쓸 수 없음"을 돌려준다.

## 흐름

1. `checkForUpdate()` — Play에 새 버전이 있는지 묻는다.
2. `startFlexibleUpdate()` — Play가 띄우는 동의 창을 연다. 사용자가 선택을
   끝낸 뒤에 완료되며, 결과는 `accepted` / `canceled` / `failed` / `unavailable`이다.
   동의하면 내려받기는 백그라운드에서 진행되고 사용자는 앱을 계속 쓸 수 있다.
3. `installStates` — 내려받기 진행률과 상태가 흘러온다.
4. 상태가 `downloaded`가 되면 `completeUpdate()`를 호출한다. Play가 설치하고
   앱을 재시작한다. **호출 시점은 사용자가 고르게 해야 한다.**

앱을 다시 열었을 때 `checkForUpdate()`가 `downloaded`를 돌려주면, 지난번에 받아
둔 업데이트가 아직 설치되지 않은 것이다. 다시 설치를 권해야 한다.

## 강제 업데이트

`startImmediateUpdate()`는 Play가 전체 화면을 덮고 내려받기·설치·재시작까지
맡는 흐름이다. 앱을 막으므로 반드시 필요한 버전에만 쓴다.

`checkForUpdate()` 응답에는 판단에 필요한 값이 함께 실려 온다:

- `installedVersionCode` — Play가 아니라 `PackageManager`에서 읽는다. 최소 요구
  버전과 비교하려면 필요한데, 그것만을 위해 왕복을 한 번 더 하거나 패키지를
  하나 더 넣을 이유가 없다.
- `immediateAllowed` — 이 기기에서 즉시 업데이트가 가능한지 Play가 판단한 값.
- `availability`가 `inProgress`면 시작해 둔 즉시 업데이트가 멈춘 것이다.
  안드로이드 가이드대로 앱 복귀 시 다시 띄워야 하고, `canStartImmediateUpdate`가
  이 경우를 포함한다.

Play의 `updatePriority`도 함께 실어 오지만 이 앱에서는 쓰지 않는다. Play Console
화면으로는 넣을 수 없고 Publishing API로만 지정할 수 있으며, 한 번 롤아웃하면
바꾸지도 못한다. 손으로 aab를 올리는 동안에는 늘 0이다.

## 테스트

인앱 업데이트는 **Play 스토어가 설치한 앱**에서만 동작한다. `flutter run`으로
올린 디버그 빌드에서는 `checkForUpdate()`가 실패(`update_check_failed`)하며,
이는 정상이다. 실제 동작은
[내부 앱 공유](https://developer.android.com/guide/playcore/in-app-updates/test)로
확인한다.

## 참고

- https://developer.android.com/guide/playcore/in-app-updates
- https://developer.android.com/guide/playcore/in-app-updates/kotlin-java
