# Nower macOS - Claude Context

## 프로젝트 개요
Nower는 macOS 일정 관리 앱으로, Apple Human Interface Guidelines와 WCAG 접근성 기준을 준수하여 개발되었습니다. SwiftUI 기반으로 구현되었으며, iOS 버전과 동일한 디자인 시스템을 공유합니다.

## 핵심 디자인 원칙

### 1. Apple HIG 준수
- **다크모드 필수 지원**: 모든 UI 컴포넌트는 라이트/다크 모드를 완전히 지원합니다.
- **시스템 네이티브 느낌**: macOS 네이티브 컴포넌트와 일관된 UX 제공
- **동적 색상 사용**: `ThemeManager.isDarkMode`를 사용하여 자동 다크모드 전환
- **윈도우 관리**: DraggableWindow를 통한 창 위치 기억 및 이동 제어

### 2. 접근성 (WCAG AA)
- **색상 대비 최소 4.5:1**: 모든 텍스트는 배경 대비 4.5:1 이상 유지
- **큰 텍스트 대비 3:1**: 18pt 이상 또는 14pt 이상 bold 텍스트는 3:1 이상
- **클릭 타겟 최소 44pt**: 모든 인터랙티브 요소는 최소 44pt 크기 (macOS HIG 기준)

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
- WCAG 4.5:1 대비 기준을 충족하도록 자동 계산

#### 버튼 색상 (HIG 준수)
- **buttonBackground**: #007AFF (시스템 블루)
- **buttonTextColor**: #FFFFFF (흰색)
- **buttonSecondaryBackground**: 다크모드에 따라 자동 조정

### 4. 레이아웃 시스템
- **8pt 그리드 시스템**: 모든 간격은 4pt 또는 8pt의 배수
- **주 단위 캘린더**: 달력을 주 단위로 구성하여 기간별 일정이 자연스럽게 연결됨
- **셀 간격 없음**: 연결된 느낌을 위해 셀 간 간격 제거
- **고정 높이 셀**: 주 내 모든 날짜 셀의 높이를 동일하게 설정하여 기간별 일정이 끊기지 않도록 함

## 주요 컴포넌트

### ContentView
- 메인 뷰 컨테이너
- 월 변경 버튼, 일일 명언, 요일 헤더 포함
- 팝업 오버레이 관리

### CalendarGridView
- 주별로 구성된 달력 뷰
- ScrollView를 통한 스크롤 지원
- 드래그 앤 드롭 기능 지원

### WeekView
- 한 주를 표시하는 컨테이너
- GeometryReader를 사용하여 모든 셀의 높이를 동일하게 설정
- 7개의 DayView를 가로로 배치

### DayView
- 개별 날짜 표시
- 날짜 라벨, 공휴일, 일정 목록 포함
- 기간별 일정과 단일 일정 모두 지원
- 드롭 영역으로 사용 가능

### EventCapsuleView
- 일정을 표시하는 캡슐 뷰
- 기간별 일정의 경우 연결된 형태로 표시 (시작/중간/종료 위치별 스타일)
- 단일 일정은 둥근 모서리
- 드래그 기능 지원 (단일 일정만)

### AddEventView
- 일정 추가 팝업 뷰
- 단일 일정, 반복 일정, 다중 일정, 기간별 일정 지원
- 색상 선택 UI 포함
- ScrollView를 통한 스크롤 지원

### EditTodoPopupView
- 일정 편집 팝업 뷰
- 기간별 일정 수정 지원
- 삭제, 반복 전체 삭제 기능 포함

## 색상 사용 가이드

### AppColors 사용
```swift
// 동적 색상 사용 (권장)
Text("Hello")
    .foregroundColor(AppColors.textPrimary)
    .background(AppColors.background)

// 테마 색상 사용
let eventColor = AppColors.color(for: "skyblue")
Text("Event")
    .foregroundColor(Color.white) // 배경색에 맞춰 자동 선택
    .background(eventColor)

// 버튼 색상 사용 (HIG 준수)
Button("Save") {
    // action
}
.foregroundColor(AppColors.buttonTextColor)
.background(AppColors.buttonBackground)
```

### 색상 정의 위치
- **Extension/AppColors.swift**: 모든 색상 정의
- **ThemeManager**: 다크모드 감지 로직

## 개발 가이드라인

### 새로운 UI 컴포넌트 추가 시
1. **다크모드 필수 지원**: 항상 라이트/다크 모드 색상 제공
2. **대비 확인**: 텍스트 색상은 배경 대비 4.5:1 이상 유지
3. **동적 색상 사용**: 하드코딩된 색상 금지, AppColors 사용
4. **테스트**: 라이트/다크 모드 모두에서 UI 확인
5. **HIG 준수**: 버튼, 텍스트 필드 등은 macOS HIG 가이드라인 준수

### 코드 스타일
- `AppColors` struct를 통한 색상 접근
- `ThemeManager.isDarkMode`로 다크모드 감지
- SwiftUI의 `@Environment` 활용 권장

### 윈도우 관리
- `DraggableWindow`를 통한 창 위치 기억
- `isMovableByWindowBackground = false`로 배경 드래그 방지
- 타이틀바 또는 지정된 영역에서만 창 이동 가능

## 파일 구조

### 색상 및 디자인
- `Extension/AppColors.swift`: 색상 정의
- `Extension/AppIcons.swift`: 아이콘 정의
- `ThemeManager`: 다크모드 감지

### 캘린더 관련
- `View/View/ContentView.swift`: 메인 뷰
- `View/View/CalendarGridView.swift`: 캘린더 그리드
- `View/View/WeekView.swift`: 주 단위 뷰
- `View/View/DayView.swift`: 날짜 뷰
- `View/View/EventCapsuleView.swift`: 일정 캡슐
- `View/View/AddEventView.swift`: 일정 추가 뷰
- `View/View/EditTodoPopupView.swift`: 일정 편집 뷰

### 윈도우 관리
- `DraggableWindow.swift`: 커스텀 윈도우 클래스
- `AppDelegate.swift`: 앱 라이프사이클 및 윈도우 관리
- `SettingsManager.swift`: 설정 관리

## macOS 특화 기능

### 윈도우 관리
- 창 위치 기억 기능
- 창 고정 기능 (isPositionLocked)
- 배경 드래그 방지 (타이틀바에서만 이동)

### 드래그 앤 드롭
- 일정을 마우스로 드래그하여 다른 날짜로 이동
- 기간별 일정은 이동 불가
- ID 기반 이동으로 안정성 향상

### 기간별 일정 표시
- 여러 날짜에 걸친 일정을 연결된 형태로 표시
- 주 내 모든 셀의 높이를 동일하게 설정하여 끊김 방지
- 시작일, 중간일, 종료일별 스타일 적용

## 업데이트 이력

### 2025-05-12
- 다크모드 완전 지원 추가
- WCAG 4.5:1 대비 기준 준수
- Apple HIG 가이드라인 적용
- 주 단위 캘린더 구조로 변경
- 기간별 일정 지원 추가
- 드래그 앤 드롭 기능 추가
- 윈도우 관리 기능 개선
- 요일 헤더와 날짜 셀 정렬 개선

## 참고 자료
- [Apple Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [WCAG 2.1 Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Color Contrast Analyzer](https://www.tpgi.com/color-contrast-checker/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
