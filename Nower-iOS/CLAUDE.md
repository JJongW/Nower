# Nower iOS - Claude Context

## 프로젝트 개요
Nower는 iOS 일정 관리 앱으로, Apple Human Interface Guidelines와 WCAG 접근성 기준을 준수하여 개발되었습니다.

## 핵심 디자인 원칙

### 1. Apple HIG 준수
- **다크모드 필수 지원**: 모든 UI 컴포넌트는 라이트/다크 모드를 완전히 지원합니다.
- **시스템 네이티브 느낌**: iOS 네이티브 컴포넌트와 일관된 UX 제공
- **동적 색상 사용**: `UIColor { trait in ... }` 클로저를 사용하여 자동 다크모드 전환

### 2. 접근성 (WCAG AA)
- **색상 대비 최소 4.5:1**: 모든 텍스트는 배경 대비 4.5:1 이상 유지
- **큰 텍스트 대비 3:1**: 18pt 이상 또는 14pt 이상 bold 텍스트는 3:1 이상
- **터치 타겟 최소 44pt**: 모든 인터랙티브 요소는 최소 44pt 크기

### 3. 색상 시스템

#### 기본 색상
- **배경 (라이트)**: #FFFFFF
- **배경 (다크)**: #000000
- **텍스트 기본 (라이트)**: #0F0F0F (대비 15.8:1)
- **텍스트 기본 (다크)**: #F5F5F7 (대비 16.1:1)

#### 강조 색상
- **라이트 모드**: #FF7E62
- **다크 모드**: #FF9A85 (더 밝게 조정)

#### 테마 색상 (일정 카테고리)
- skyblue, peach, lavender, mintgreen, coralred
- 모든 색상은 다크모드에서 자동 조정되어 가독성 향상
- **텍스트 색상은 배경색에 따라 자동 선택** (밝은 배경 → 어두운 텍스트, 어두운 배경 → 밝은 텍스트)
- WCAG 4.5:1 대비 기준을 충족하도록 `contrastingTextColor` 함수로 자동 계산

### 4. 레이아웃 시스템
- **8pt 그리드 시스템**: 모든 간격은 4pt 또는 8pt의 배수
- **주 단위 캘린더**: 달력을 주 단위로 구성하여 기간별 일정이 자연스럽게 연결됨
- **셀 간격 없음**: 연결된 느낌을 위해 셀 간 간격 제거

## 주요 컴포넌트

### CalendarView
- 주 단위로 구성된 달력 뷰
- 각 주는 WeekView로 표시되며, 7개의 DayView 포함
- 다크모드 자동 지원

### WeekView / WeekCell
- 한 주를 표시하는 컨테이너
- 터치 이벤트를 처리하여 정확한 날짜 선택

### DayView
- 개별 날짜 표시
- 날짜 라벨, 공휴일, 일정 목록 포함
- 기간별 일정과 단일 일정 모두 지원

### EventCapsuleView
- 일정을 표시하는 캡슐 뷰
- 기간별 일정의 경우 연결된 형태로 표시 (시작/중간/종료 위치별 스타일)
- 단일 일정은 둥근 모서리

## 색상 사용 가이드

### AppColors Enum 사용
```swift
// 동적 색상 사용 (권장)
label.textColor = AppColors.textPrimary
view.backgroundColor = AppColors.background

// 테마 색상 사용 및 대비 텍스트 색상 자동 선택
let eventColor = AppColors.color(for: "skyblue")
label.textColor = AppColors.contrastingTextColor(for: eventColor) // 배경색에 맞춰 자동 선택

// EventCapsuleView는 자동으로 대비 색상을 사용합니다
```

### 색상 정의 위치
- **UIColor+Extension.swift**: 모든 색상 정의
- **Assets.xcassets**: Asset 카탈로그의 색상셋 (자동 동기화)

## 개발 가이드라인

### 새로운 UI 컴포넌트 추가 시
1. **다크모드 필수 지원**: 항상 라이트/다크 모드 색상 제공
2. **대비 확인**: 텍스트 색상은 배경 대비 4.5:1 이상 유지
3. **동적 색상 사용**: 하드코딩된 색상 금지, AppColors 사용
4. **테스트**: 라이트/다크 모드 모두에서 UI 확인

### 코드 스타일
- `AppColors` enum을 통한 색상 접근
- `UIColor { trait in ... }` 클로저로 동적 색상 정의
- 시스템 색상 사용 권장 (UIColor.label, UIColor.systemBackground 등)

## 파일 구조

### 색상 및 디자인
- `Resources/Extension/UIColor+Extension.swift`: 색상 정의
- `Assets.xcassets/`: Asset 카탈로그 (색상셋 포함)

### 캘린더 관련
- `Presentation/Calendar/View/CalendarView.swift`: 메인 캘린더 뷰
- `Presentation/Calendar/View/Cell/WeekView.swift`: 주 단위 뷰
- `Presentation/Calendar/View/Cell/DayView.swift`: 날짜 뷰
- `Presentation/Calendar/View/Cell/EventCapsuleView.swift`: 일정 캡슐

## 업데이트 이력

### 2025-01-26
- 다크모드 완전 지원 추가
- WCAG 4.5:1 대비 기준 준수
- Apple HIG 가이드라인 적용
- 주 단위 캘린더 구조로 변경
- 색상 대비 자동 선택 기능 추가: 배경색에 따라 텍스트 색상을 자동으로 선택하여 가독성 향상

## 참고 자료
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WCAG 2.1 Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Color Contrast Analyzer](https://www.tpgi.com/color-contrast-checker/)
