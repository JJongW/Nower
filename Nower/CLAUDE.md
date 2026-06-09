# Nower macOS — Claude Context & Figma Integration Rules

## Brand (read before any UI/UX/copy/product decision)

Read `.claude/plans/brand/17-ai-context.md` and `.claude/plans/brand/14-product-principles.md`
before making UI, UX, copy, branding, or product decisions.
The one-line test: "이 변경이 사용자가 하루를 덜 망가지게 쓰도록 돕는가?" 아니면 다시 생각한다.
(전체 브랜드 바이블: `.claude/plans/brand/`. 밀도 채점식: `.claude/plans/density-scoring-spec.md`.)

## 프로젝트 개요

Nower macOS는 SwiftUI 기반 달력 앱입니다. Apple HIG와 WCAG AA를 준수하며, iOS 버전과 공통 색상 시스템·도메인 모델을 공유합니다.

**Platform:** macOS, SwiftUI
**Min target:** macOS 13+
**Architecture:** Clean Architecture (Presentation → Domain → Data)

---

## 디자인 시스템 — 토큰

### 색상 토큰 (`Extension/AppColors.swift`)

모든 색상은 `AppColors` struct에 정의. **하드코딩 절대 금지.**

| 토큰 | 라이트 | 다크 | 용도 |
|------|--------|------|------|
| `textPrimary` | `#0F0F0F` | `#F5F5F7` | 기본 텍스트 |
| `textHighlighted` | `#FF7E62` | `#FF9A85` | 오늘 날짜, 강조 |
| `background` | `#FFFFFF` | `#000000` | 앱 배경 |
| `popupBackground` | `#FFFFFF` | `#1C1C1E` | 팝업/모달 배경 |
| `textFieldBackground` | `#F7F7F7` | `#1C1C1E` | 입력 필드 |
| `todoBackground` | `#F2F2F7` | `#2C2C2E` | 카드/셀 배경 |
| `buttonBackground` | `#007AFF` | `#007AFF` | 메인 버튼 |
| `buttonTextColor` | `#FFFFFF` | `#FFFFFF` | 버튼 텍스트 |

#### 이벤트 테마 색상 (5종)

| 이름 | 라이트 | 다크 |
|------|--------|------|
| `skyblue` | `#73B3D9` | `#59A0CC` |
| `peach` | `#F2BF8C` | `#F2A673` |
| `lavender` | `#B399D9` | `#A68CCC` |
| `mintgreen` | `#66B399` | `#4DA68C` |
| `coralred` | `#F28C80` | `#F28073` |

#### 톤 시스템 (1–8)
- `"skyblue-1"` ~ `"skyblue-8"` (밝음 → 어두움)
- `AppColors.colorTones(for: "skyblue")` → `[Color]` (8개)
- `AppColors.color(for: "skyblue-3")` 으로 직접 접근

#### 색상 사용 패턴
```swift
// 의미 기반 색상 (권장)
Text("Hello")
    .foregroundColor(AppColors.textPrimary)
    .background(AppColors.background)

// 이벤트 테마 색상
let bg = AppColors.color(for: event.colorName)
let fg = AppColors.contrastingTextColor(for: bg)  // WCAG 자동 계산

// 다크모드 감지
ThemeManager.isDarkMode  // Bool
```

---

### 타이포그래피

전용 파일 없음. 인라인 시스템 폰트 사용. 아래 패턴 따를 것.

| 용도 | 폰트 | 크기 | 굵기 |
|------|------|------|------|
| 월/년 헤더 | `.title` | - | `.bold` |
| 요일 헤더 | `.system` | 14pt | `.medium` |
| 날짜 숫자 | `.system` | 12pt | `.medium` |
| 이벤트 제목 | `.system` | 10pt | `.medium` |
| 이벤트 시간 | `.system + .monospacedDigit()` | 9pt | `.bold` |
| 공휴일 | `.system` | 9pt | `.regular` |

```swift
// 시간 표시 패턴 (monospaced 필수)
Text(timeString)
    .font(.system(size: 9, weight: .bold).monospacedDigit())

// 오버플로우 처리 필수
.lineLimit(1)
.truncationMode(.tail)
.minimumScaleFactor(0.8)
```

---

### 스페이싱 / 사이징

**8pt 그리드 시스템.** 4pt 또는 8pt 배수 사용.

| 토큰 | 값 | 용도 |
|------|----|------|
| `eventHeight` | 20pt | 이벤트 캡슐 높이 |
| `eventSpacing` | 2pt | 이벤트 사이 간격 |
| `eventHPadding` | 6pt | 이벤트 수평 패딩 |
| `eventVPadding` | 3pt | 이벤트 수직 패딩 |
| `dayLabelHeight` | 14pt | 날짜 숫자 영역 |
| `holidayLabelHeight` | 8pt | 공휴일 라벨 높이 |
| `topPadding` | 2pt | 셀 상단 패딩 |
| `bottomPadding` | 4pt | 셀 하단 패딩 |
| `todayCircleSize` | 24pt | 오늘 날짜 원 크기 |

**창 크기:**
```swift
let windowSize = CGSize(width: 1024, height: 720)
window.minSize = CGSize(width: 700, height: 500)
```

---

## 컴포넌트 라이브러리

### 뷰 계층 구조
```
ContentView
├── Header (월 네비게이션, 버튼들)
├── DailyQuote
├── Weekday Headers
└── CalendarGridView
    └── ScrollView → VStack
        └── WeekView (× n주)
            ├── HStack of DayView (× 7)
            └── EventCapsule overlay
```

### 컴포넌트 위치 (`View/View/`)

| 컴포넌트 | 파일 | 핵심 역할 |
|---------|------|---------|
| `ContentView` | `ContentView.swift` | 메인 컨테이너, 팝업 관리 |
| `CalendarGridView` | `CalendarGridView.swift` | 주별 달력 그리드, drag-drop |
| `WeekView` | `WeekView.swift` | 1주 컨테이너, GeometryReader |
| `DayView` | `DayView.swift` | 날짜 셀, drop target |
| `EventCapsuleView` | `EventCapsuleView.swift` | 이벤트 표시, 드래그 |
| `AddEventView` | `AddEventView.swift` | 이벤트 생성 팝업 |
| `EditTodoPopupView` | `EditTodoPopupView.swift` | 이벤트 편집 팝업 |
| `ToastView` | `ToastView.swift` | 알림 토스트 |
| `SyncStatusView` | `SyncStatusView.swift` | iCloud 동기화 상태 |
| `TemplateAutocompleteView` | `TemplateAutocompleteView.swift` | 자동완성 팝업 |
| `ColorVariationPickerView` | `ColorVariationPickerView.swift` | 색상 선택 |

### EventCapsuleView 상태 로직
```swift
// 기간 이벤트 렌더링 — 4가지 상태
enum CapsulePosition { case single, start, middle, end }

// start: 왼쪽 둥근 모서리, 오른쪽 직각
// middle: 양쪽 직각 (연속된 띠)
// end: 왼쪽 직각, 오른쪽 둥근 모서리
// single: 양쪽 둥근 모서리
```

---

## SwiftUI 패턴

### 상태 관리
```swift
@EnvironmentObject var viewModel: CalendarViewModel
@EnvironmentObject var themeManager: ThemeManager
@EnvironmentObject var settingsManager: SettingsManager
@StateObject private var syncViewModel = SyncStatusViewModel()
@State private var isPopupVisible: Bool = false
```

### 레이아웃 패턴
```swift
// 7열 그리드 (항상 GeometryReader 사용)
GeometryReader { geometry in
    HStack(spacing: 0) {
        ForEach(days) { day in
            DayView(day: day)
                .frame(width: geometry.size.width / 7)
        }
    }
}

// 꽉 차는 너비
.frame(maxWidth: .infinity, alignment: .leading)

// VStack 간격 없음 (연결된 주 느낌)
VStack(spacing: 0) { ... }
```

### Drag & Drop
```swift
.onDrag { NSItemProvider(object: eventId as NSString) }
.onDrop(of: [.text], isTargeted: nil) { providers in ... }
```

---

## 아이콘 시스템 (`Extension/AppIcons.swift`)

SF Symbols 사용. 인라인 문자열 대신 `AppIcons` 상수 참조.

```swift
// 현재 정의된 심볼들
AppIcons.plus           // "plus"
AppIcons.chevronLeft    // "chevron.left"
AppIcons.chevronRight   // "chevron.right"
AppIcons.gear           // "gear"
// 추가 시 AppIcons.swift에 상수 추가
```

---

## macOS 특화 기능

### 창 관리 (`DraggableWindow.swift`)
- `UserDefaults`로 창 위치 기억
- `isMovableByWindowBackground = false` (타이틀바만 이동)
- `canJoinAllSpaces` vs `현재 Space만` (설정에 따라)
- Desktop 위젯 모드: `.accessory` activation policy (Dock 숨김)

### 알림 (NotificationCenter)
```swift
NotificationCenter.default.post(name: .nowerPopupOpened, object: nil)
NotificationCenter.default.post(name: .nowerPopupClosed, object: nil)
```

---

## Figma → SwiftUI 변환 규칙

Figma 디자인을 코드로 전환할 때 아래 규칙 적용:

1. **색상**: Figma 색상 → `AppColors` 토큰으로 매핑. 신규 색상은 `AppColors.swift`에 추가 후 사용.
2. **폰트**: `SF Pro` → `.system(size:, weight:)`. 고정 pt 값 그대로 적용.
3. **스페이싱**: `8pt 그리드` 준수. Figma 값이 5pt이면 4pt 또는 8pt로 반올림.
4. **컴포넌트 재사용**: 기존 컴포넌트 있으면 신규 생성 금지. 위 컴포넌트 테이블 먼저 확인.
5. **다크모드**: Figma 라이트 디자인만 있어도, 구현 시 반드시 다크모드 대응 포함.
6. **절대 좌표 금지**: Figma absolute position → SwiftUI `VStack/HStack/ZStack + GeometryReader`로 변환.
7. **이벤트 캡슐**: Figma의 이벤트 바(bar) 디자인 → `EventCapsuleView` 재사용.

---

## 접근성 (WCAG AA)

- **텍스트 대비 4.5:1 이상** (모든 텍스트)
- **큰 텍스트 3:1** (18pt+ 또는 14pt+ bold)
- **터치/클릭 타겟 44pt 이상**
- `AppColors.contrastingTextColor(for: background)` 로 자동 계산

---

## 개발 워크플로우 (필수)

코드 변경 후: `/why` → `/validate` → `/ship`

1. **구현 후 즉시** `/why` — What/Why 기록 (`docs/decisions/`)
2. 선택적 `/validate` — 계획 대비 검증
3. 배포 시 `/ship` — 이슈 + PR + 머지

---

## 참고 자료
- [Apple HIG macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/)
- [SwiftUI Docs](https://developer.apple.com/documentation/swiftui/)
