# Nower iOS — Claude Context & Figma Integration Rules

## Brand (read before any UI/UX/copy/product decision)

Read `.claude/plans/brand/17-ai-context.md` and `.claude/plans/brand/14-product-principles.md`
before making UI, UX, copy, branding, or product decisions.
The one-line test: "이 변경이 사용자가 하루를 덜 망가지게 쓰도록 돕는가?" 아니면 다시 생각한다.
(전체 브랜드 바이블: `.claude/plans/brand/`. 밀도 채점식: `.claude/plans/density-scoring-spec.md`.)

## 프로젝트 개요

Nower iOS는 UIKit 기반 달력 앱입니다. Apple HIG와 WCAG AA를 준수하며, macOS 버전과 공통 색상 시스템·도메인 모델을 공유합니다.

**Platform:** iOS, UIKit (일부 SwiftUI 위젯)
**Min target:** iOS 16+
**Architecture:** Clean Architecture (Presentation → Domain → Data)

---

## 디자인 시스템 — 토큰

### 색상 토큰 (`Resources/Extension/UIColor+Extension.swift`)

모든 색상은 `AppColors` enum에 정의. **하드코딩 절대 금지.**
`UIColor { trait in ... }` 클로저로 자동 다크모드 지원.

| 토큰 | 라이트 | 다크 | 용도 |
|------|--------|------|------|
| `AppColors.textPrimary` | `#0F0F0F` | `#F5F5F7` | 기본 텍스트 |
| `AppColors.textHighlighted` | `#FF7E62` | `#FF9A85` | 오늘 날짜, 강조 |
| `AppColors.background` | `#FFFFFF` | `#000000` | 앱 배경 |
| `AppColors.popupBackground` | `#FFFFFF` | `#1C1C1E` | 팝업/모달 배경 |
| `AppColors.textFieldBackground` | `#F7F7F7` | `#1C1C1E` | 입력 필드 |
| `AppColors.todoBackground` | `#F2F2F7` | `#2C2C2E` | 카드/셀 배경 |
| `AppColors.buttonBackground` | `#007AFF` | `#007AFF` | 메인 버튼 |
| `AppColors.buttonTextColor` | `#FFFFFF` | `#FFFFFF` | 버튼 텍스트 |

#### 이벤트 테마 색상 (5종) — Asset Catalog + 코드 이중 정의

| 이름 | 라이트 | 다크 | Asset |
|------|--------|------|-------|
| `skyblue` | `#73B3D9` | `#59A0CC` | `skyblue.colorset` |
| `peach` | `#F2BF8C` | `#F2A673` | `peach.colorset` |
| `lavender` | `#B399D9` | `#A68CCC` | `lavender.colorset` |
| `mintgreen` | `#66B399` | `#4DA68C` | `mintgreen.colorset` |
| `coralred` | `#F28C80` | `#F28073` | `coralred.colorset` |

#### 톤 시스템 (1–8)
- `AppColors.colorTones(for: "skyblue")` → `[UIColor]` (8개)
- 밝음(1) → 어두움(8) 자동 계산

#### 색상 사용 패턴
```swift
// UIKit 기본 패턴
label.textColor = AppColors.textPrimary
view.backgroundColor = AppColors.background

// 이벤트 테마 색상 + 대비 텍스트 자동 선택
let bg = AppColors.color(for: event.colorName)
let fg = AppColors.contrastingTextColor(for: bg)  // WCAG 자동 계산
label.textColor = fg

// Dynamic UIColor 직접 정의 패턴 (확장 시)
UIColor { trait in
    trait.userInterfaceStyle == .dark
        ? UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
        : UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1)
}
```

---

### 타이포그래피

전용 파일 없음. 인라인 시스템 폰트 사용.

| 용도 | 폰트 | 크기 | 굵기 |
|------|------|------|------|
| 월/년 헤더 | `.systemFont` | 17pt | `.bold` |
| 요일 헤더 | `.systemFont` | 12–14pt | `.medium` |
| 날짜 숫자 | `.systemFont` | 12pt | `.medium` |
| 이벤트 제목 | `.systemFont` | 10pt | `.medium` |
| 이벤트 시간 | `.monospacedDigitSystemFont` | 9pt | `.bold` |
| 공휴일 | `.systemFont` | 9pt | `.regular` |

```swift
// 시간 표시 (monospaced 필수)
label.font = .monospacedDigitSystemFont(ofSize: 9, weight: .bold)

// 오버플로우 처리 필수
label.numberOfLines = 1
label.lineBreakMode = .byTruncatingTail
label.adjustsFontSizeToFitWidth = true
label.minimumScaleFactor = 0.8
```

---

### 스페이싱 / 사이징

**8pt 그리드 시스템.** 4pt 또는 8pt 배수 사용.

| 토큰 | 값 | 용도 |
|------|----|------|
| `eventHeight` | 18pt | 이벤트 캡슐 높이 |
| `eventSpacing` | 2pt | 이벤트 사이 간격 |
| `eventHPadding` | 6pt | 이벤트 수평 패딩 |
| `eventVPadding` | 3pt | 이벤트 수직 패딩 |
| `dayLabelHeight` | 14pt | 날짜 숫자 영역 |
| `holidayLabelHeight` | 8pt | 공휴일 라벨 높이 |
| `todayCircleSize` | 24pt | 오늘 날짜 원 크기 |
| `minTouchTarget` | 44pt | 최소 터치 영역 (HIG) |

---

## 컴포넌트 라이브러리

### 뷰 계층 구조
```
CalendarViewController
└── CalendarView
    └── UIScrollView → WeekCell rows
        └── WeekView (× n주)
            ├── DayView (× 7)
            │   └── EventCapsuleView (× n)
            └── Period event overlay
```

### 컴포넌트 위치 (`Presentation/Calendar/`)

| 컴포넌트 | 파일 | 핵심 역할 |
|---------|------|---------|
| `CalendarView` | `View/CalendarView.swift` | 메인 달력 컨테이너 |
| `WeekCell / WeekView` | `View/Cell/WeekView.swift` | 1주 컨테이너 |
| `DayView` | `View/Cell/DayView.swift` | 날짜 셀 |
| `EventCapsuleView` | `View/Cell/EventCapsuleView.swift` | 이벤트 표시 |
| `EventCell` | `View/Cell/EventCell.swift` | 이벤트 리스트 셀 |
| `NewEventView` | `View/NewEventView.swift` | 이벤트 생성 뷰 |
| `EventListView` | `View/EventListView.swift` | 이벤트 목록 |
| `TimePickerView` | `View/TimePickerView.swift` | 시간 선택 |
| `RecurrencePickerView` | `View/RecurrencePickerView.swift` | 반복 설정 |

### EventCapsuleView 상태 로직 (macOS와 동일)
```swift
// 기간 이벤트 — 4가지 렌더링 상태
// single: 양쪽 둥근
// start: 왼쪽 둥근, 오른쪽 직각
// middle: 양쪽 직각
// end: 왼쪽 직각, 오른쪽 둥근
```

---

## Asset Catalog (`Assets.xcassets/`)

### 색상셋 (Color Sets)
```
AccentColor.colorset
background.colorset
textPrimary.colorset
textMain.colorset
textHighlighted.colorset
popupBackground.colorset
skyblue.colorset
peach.colorset
lavender.colorset
mintgreen.colorset
coralred.colorset
```

### 이미지셋 (Image Sets)
```
ic_alarm.imageset      — 알람 아이콘
ic_left_arrow.imageset — 이전 달 버튼
ic_right_arrow.imageset — 다음 달 버튼
ic_time.imageset       — 시간 선택 아이콘
```

**아이콘 사용 패턴:**
```swift
// Asset 이미지
imageView.image = UIImage(named: "ic_alarm")

// SF Symbols (권장, 시스템 아이콘)
imageView.image = UIImage(systemName: "plus")
imageView.image = UIImage(systemName: "chevron.left")
```

---

## 위젯 (`NowerTodayWidgetExtension/`)

SwiftUI 기반 위젯. 동일한 색상 토큰 사용.
- 월간 캘린더 위젯
- Asset: `NowerWidget/Assets.xcassets/`

---

## UIKit 패턴

### ViewController 구성
```swift
class CalendarViewController: UIViewController {
    private let viewModel: CalendarViewModel
    // Combine 또는 delegation으로 ViewModel 바인딩
}
```

### 색상 적용 패턴
```swift
// viewDidLoad 또는 traitCollectionDidChange에서 적용
override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
        updateColors()
    }
}

private func updateColors() {
    view.backgroundColor = AppColors.background
    titleLabel.textColor = AppColors.textPrimary
}
```

### 레이아웃 패턴
```swift
// Auto Layout (스토리보드 아님, 코드 레이아웃)
NSLayoutConstraint.activate([
    eventCapsule.heightAnchor.constraint(equalToConstant: 18),
    eventCapsule.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
    eventCapsule.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2)
])
```

---

## Figma → UIKit 변환 규칙

1. **색상**: Figma 색상 → `AppColors` 토큰으로 매핑. 신규 색상은 `UIColor+Extension.swift` + `Assets.xcassets`에 동시 추가.
2. **폰트**: `SF Pro` → `UIFont.systemFont(ofSize:, weight:)`. 고정 pt 값 그대로.
3. **스페이싱**: `8pt 그리드` 준수. Figma 값이 5pt이면 4pt 또는 8pt로 반올림.
4. **컴포넌트 재사용**: 기존 컴포넌트 있으면 신규 생성 금지. 위 컴포넌트 테이블 먼저 확인.
5. **다크모드**: Figma 라이트 디자인만 있어도, 구현 시 반드시 다크모드 대응 포함.
6. **이벤트 캡슐**: Figma의 이벤트 바(bar) 디자인 → `EventCapsuleView` 재사용.
7. **터치 타겟**: 아무리 작은 요소도 실제 터치 가능 영역은 44pt 이상.

---

## 접근성 (WCAG AA)

- **텍스트 대비 4.5:1 이상** (모든 텍스트)
- **큰 텍스트 3:1** (18pt+ 또는 14pt+ bold)
- **터치 타겟 44pt 이상** (iOS HIG 필수)
- `AppColors.contrastingTextColor(for: background)` 로 자동 계산
- `isAccessibilityElement`, `accessibilityLabel` 필요한 커스텀 뷰에 적용

---

## 개발 워크플로우 (필수)

코드 변경 후: `/why` → `/validate` → `/ship`

1. **구현 후 즉시** `/why` — What/Why 기록 (`docs/decisions/`)
2. 선택적 `/validate` — 계획 대비 검증
3. 배포 시 `/ship` — 이슈 + PR + 머지

---

## 참고 자료
- [Apple HIG iOS](https://developer.apple.com/design/human-interface-guidelines/ios)
- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/)
- [UIKit Docs](https://developer.apple.com/documentation/uikit/)
