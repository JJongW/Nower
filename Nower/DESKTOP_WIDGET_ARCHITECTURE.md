# Desktop Widget Architecture (macOS)

데스크톱 배경 위젯처럼 동작하는 캘린더 앱의 AppKit 기반 구현 가이드.

## 1. 동작 규칙 요약

| 규칙 | 구현 |
|------|------|
| 배경화면과 동일 레이어 | `NSWindow.Level(desktopWindow + 1)` |
| Mission Control에 미표시 | `collectionBehavior` 포함 `.transient` |
| Cmd+Tab에 미표시 | `NSApplication.setActivationPolicy(.accessory)` |
| Dock에 미표시 | `.accessory` (동일) |
| 테두리 없음, 이동/리사이즈 불가 | `styleMask = .borderless`, `isMovable = false`, `setFrame*` 오버라이드 |
| 더블클릭 → Add Schedule 창 | `sendEvent`에서 `NSEvent.clickCount == 2` 처리 후 별도 NSWindow |
| Add 창은 일반 창 | `AddScheduleWindowController`, `level = .normal` |
| Space 전환 시 고정 | `collectionBehavior` `.canJoinAllSpaces` |
| Stage Manager 호환 | `.accessory` + `.transient` 조합으로 동작 |

---

## 2. Window Level 및 collectionBehavior

### Window Level

- **`CGWindowLevelForKey(.desktopWindow) + 1`**  
  배경화면과 같은 레이어에 두고, +1로 데스크톱 아이콘 바로 위에 그리기 위해 사용.  
  시스템 위젯과 비슷한 “배경에 붙어 있는” 느낌을 주려면 이 레벨이 적절함.

### collectionBehavior

- **`.canJoinAllSpaces`**  
  모든 Space에 동일 창이 보이도록 함. Space를 바꿔도 캘린더가 같은 위치에 고정된 것처럼 보임.

- **`.stationary`**  
  “이 창을 현재 Space에 묶는다”는 의미. `canJoinAllSpaces`와 함께 쓰면 OS가 조합해 처리하며, “모든 Space에 보이면서도 Space 전환 시 움직이지 않음” 동작에 기여할 수 있음.

- **`.ignoresCycle`**  
  Cmd+` 윈도우 순환에서 제외. 앱이 `.accessory`이면 Cmd+Tab 앱 전환에도 안 나오므로, “보조 앱”처럼 동작하게 함.

- **`.transient`**  
  **Mission Control(Exposé)에 표시되지 않음.** 위젯처럼 “창 목록에 안 나오는” 동작의 핵심.

---

## 3. Mission Control 엣지 케이스

- **macOS 버전/환경 차이**  
  `.transient`만으로 Mission Control에서 완전히 숨겨지지 않는 경우가 있을 수 있음.  
  그럴 때는 `collectionBehavior`를 **창을 보여주기 직전**에 한 번 더 설정하거나,  
  `.fullScreenAuxiliary` / `.fullScreenPrimary` 등 다른 플래그와 섞이지 않았는지 확인하는 것이 좋음.

- **멀티 디스플레이**  
  각 화면의 “주 모니터”에 따라 Space가 나뉘므로, `canJoinAllSpaces`를 쓰면 모든 디스플레이의 Space에 동일 창이 나타날 수 있음.

- **전원/잠금 후**  
  재개 후에도 레벨/collectionBehavior는 유지되나, 일부 환경에서는 한 번 다시 `makeKeyAndOrderFront(nil)`을 호출해 주는 편이 안전함.

---

## 4. Stage Manager 호환

- **Stage Manager ON**  
  `.accessory` 앱은 Stage Manager 그룹에 포함되지 않고, 데스크톱 위젯처럼 뒤쪽에 남는 경향이 있음.  
  `level = desktop + 1`과 `.transient` 조합이면 “배경 고정” 느낌을 유지하기에 적합함.

- **동작 확인**  
  Stage Manager를 켠 상태에서 Space 전환, Mission Control, Cmd+Tab에 캘린더/앱이 안 나오는지 반드시 확인할 것.

---

## 5. App Store / 샌드박스 리스크와 대응

| 리스크 | 대응 |
|--------|------|
| “Dock/메뉴바에 안 나오는 앱”이 사용자에게 혼란스러움 | 앱 설명·도움말에 “메뉴바에서 종료” 등 사용 방법 명시. 필요 시 설정 창에서 종료 방법 안내. |
| 권한/백그라운드 동작 | 필요한 권한(캘린더, 알림 등)은 Info.plist + 사용자 요청으로만 사용. 백그라운드 실행은 정책에 맞게 최소화. |
| Sandbox | 네트워크·파일 등 필요한 entitlement만 요청. 데스크톱 레벨 창 자체는 샌드박스와 무관. |
| Guideline 2.1 (앱 완성도) | “위젯처럼 항상 뒤에 있는 캘린더”라는 목적을 명확히 하고, 더블클릭 → Add Schedule 등 핵심 플로우가 안정적으로 동작하도록 구현. |

---

## 6. 더블클릭 감지 (AppKit)

`DesktopCalendarWindow.sendEvent(_:)`에서 처리:

- `event.type == .leftMouseDown` 이고 `event.clickCount == 2`이면 더블클릭으로 간주.
- `locationInWindow`를 `contentView` 좌표로 변환해, 캘린더 영역 안인지 확인한 뒤  
  `NotificationCenter.default.post(name: .desktopCalendarOpenAddSchedule, ...)` 로 “Add Schedule 열기” 이벤트 전달.
- `DesktopWindowController`가 이 알림을 받아 `AddScheduleWindowController`를 띄움.

SwiftUI만으로 하지 않고, **NSEvent.clickCount**와 **sendEvent**를 사용해 AppKit에서 처리하는 것이 요구사항 충족 및 동작 제어에 유리함.

---

## 7. 파일 역할

- **DesktopCalendarWindow.swift**  
  배경화면 레벨의 borderless 창, 레벨/collectionBehavior 설정, 이동·리사이즈 방지, 더블클릭 시 `OpenAddSchedule` 알림 전송.

- **DesktopWindowController.swift**  
  데스크톱 창 생성·배치, ContentView 호스팅, `openAddScheduleWithDate` 환경 주입, `OpenAddSchedule` 알림 수신 후 Add Schedule 창 표시.

- **AddScheduleWindowController.swift**  
  일반 스타일의 “새 일정” 창 (titled, closable), `AddEventView` 호스팅, 저장/취소 시 창 닫기.

- **AppDelegate**  
  `useDesktopWidgetMode == true`일 때 `setActivationPolicy(.accessory)` 및 `DesktopWindowController` 기반으로 데스크톱 위젯 모드 진입.

---

## 8. 데스크톱 위젯 모드 켜기

`AppDelegate.swift` 상단:

```swift
private let useDesktopWidgetMode = true  // true = 위젯 모드, false = 기존 일반 창 모드
```

`true`로 두면 앱 실행 시 Dock/Cmd+Tab 없이, 배경화면 레벨의 고정 캘린더 창만 표시되고, 더블클릭 시 Add Schedule 창이 일반 창으로 열림.
