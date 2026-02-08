//
//  WeekView.swift
//  Nower-iOS
//
//  Created by 신종원 on 1/26/25.
//

import UIKit
import SnapKit

/// 기간별 일정 레이아웃 정보
struct PeriodEventLayoutInfo {
    let id: UUID
    let todo: TodoItem
    let startDayIndex: Int  // 0-6 within week
    let endDayIndex: Int    // 0-6 within week
    let rowIndex: Int       // Vertical row (0, 1, 2...)
    let isFirstSegment: Bool
    let isLastSegment: Bool
}

/// 한 주를 표시하는 뷰
/// 7개의 날짜를 가로로 배치하고, 각 날짜의 일정들을 표시합니다.
/// 기간별 일정은 WeekView 레벨에서 연속된 바로 렌더링됩니다.
final class WeekView: UIView {

    // MARK: - Properties
    private var dayViews: [DayView] = []
    private var weekDays: [WeekDayInfo] = []
    private var periodEventViews: [PeriodEventOverlayView] = []
    private var periodEventRows: [[PeriodEventLayoutInfo]] = []
    private var moreEventLabel: UILabel? // "+N개" 라벨

    var onDaySelected: ((String) -> Void)? // 날짜 선택 콜백 (dateString 전달)
    var onTodoSelected: ((TodoItem, String) -> Void)? // 일정 선택 콜백 (TodoItem, dateString 전달)
    var onMoreTapped: ((String, [TodoItem]) -> Void)? // "+N개" 탭 콜백 (dateString, todos 전달)

    // MARK: - Layout Constants
    private let eventHeight: CGFloat = 18
    private let eventSpacing: CGFloat = 2 // 간격 축소 (4 → 2)
    private let periodEventTopOffset: CGFloat = 38 // 공휴일 라벨 공간 포함 (dayLabel 26pt + holidayLabel 10pt = 36pt)
    private let maxVisiblePeriodEventRows: Int = 3 // 최대 표시 가능한 기간일정 행 수

    // MARK: - UI Components

    /// 기간별 일정을 표시하는 컨테이너 뷰
    private let periodEventContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        view.backgroundColor = .clear
        return view
    }()

    private let dayContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 0
        return stackView
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        clipsToBounds = false

        addSubview(dayContainerStackView)
        addSubview(periodEventContainer)

        dayContainerStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        periodEventContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalToSuperview().offset(periodEventTopOffset)
            $0.height.equalTo(0) // 동적으로 업데이트됨
        }

        // 7개의 DayView 생성
        for _ in 0..<7 {
            let dayView = DayView()
            // DayView의 "+N개" 탭 콜백 연결
            dayView.onMoreTapped = { [weak self] dateString, todos in
                self?.onMoreTapped?(dateString, todos)
            }
            dayViews.append(dayView)
            dayContainerStackView.addArrangedSubview(dayView)
        }
    }

    /// 셀 재사용 시 기간별 일정 뷰를 초기화합니다.
    func clearPeriodEvents() {
        periodEventViews.forEach { $0.removeFromSuperview() }
        periodEventViews.removeAll()
        moreEventLabel?.removeFromSuperview()
        moreEventLabel = nil
        periodEventRows = []
    }

    // MARK: - Configuration
    /// 주 뷰를 설정합니다.
    /// - Parameter weekDays: 7개의 날짜 정보 (빈 날짜 포함 가능)
    func configure(weekDays: [WeekDayInfo]) {
        self.weekDays = weekDays

        // 기존 기간별 일정 뷰 즉시 제거 (셀 재사용 시 잔존 방지)
        periodEventViews.forEach { $0.removeFromSuperview() }
        periodEventViews.removeAll()
        moreEventLabel?.removeFromSuperview()
        moreEventLabel = nil

        // 기간별 일정 행 계산
        periodEventRows = calculatePeriodEventRows()

        // 최대 표시 가능한 행 수 제한
        let visibleRows = min(periodEventRows.count, maxVisiblePeriodEventRows)
        let hiddenEventCount = max(0, periodEventRows.count - maxVisiblePeriodEventRows)

        // 각 날짜별로 해당 날짜에 기간 일정이 있는 행 수 계산
        let periodEventRowsPerDay = calculatePeriodEventRowsPerDay(visibleRows: visibleRows)

        // DayView 설정 (각 날짜별로 실제 기간 일정이 있는 행 수만 전달)
        for (index, dayInfo) in weekDays.enumerated() {
            guard index < dayViews.count else { break }
            let periodEventCount = periodEventRowsPerDay[index] ?? 0
            dayViews[index].configure(with: dayInfo, periodEventSlotCount: periodEventCount)
        }

        // 기간별 일정 컨테이너 높이 업데이트 (표시되는 행 수만)
        let containerHeight = CGFloat(visibleRows) * (eventHeight + eventSpacing)
        periodEventContainer.snp.updateConstraints {
            $0.height.equalTo(containerHeight)
        }

        // 숨겨진 일정 개수 저장 (렌더링 시 사용)
        self.hiddenPeriodEventCount = hiddenEventCount

        // 레이아웃 갱신을 강제하여 renderPeriodEvents()가 반드시 호출되도록 보장
        setNeedsLayout()
    }

    /// 각 날짜별로 기간일정이 차지하는 행 수를 계산합니다.
    private func calculatePeriodEventRowsPerDay(visibleRows: Int) -> [Int: Int] {
        var rowsPerDay: [Int: Int] = [:]

        // 각 날짜 인덱스별로 0으로 초기화
        for dayIndex in 0..<7 {
            rowsPerDay[dayIndex] = 0
        }

        // 표시되는 행까지만 확인
        let visiblePeriodEventRows = Array(periodEventRows.prefix(visibleRows))

        // 각 행의 각 기간일정을 확인하여 해당 날짜 범위에 포함되는지 체크
        for (rowIndex, row) in visiblePeriodEventRows.enumerated() {
            for eventInfo in row {
                // 이 기간일정이 포함하는 모든 날짜 인덱스에 대해 행 수 업데이트
                for dayIndex in eventInfo.startDayIndex...eventInfo.endDayIndex {
                    let currentMaxRow = rowsPerDay[dayIndex] ?? 0
                    rowsPerDay[dayIndex] = max(currentMaxRow, rowIndex + 1)
                }
            }
        }

        return rowsPerDay
    }
    
    // 숨겨진 기간일정 개수
    private var hiddenPeriodEventCount: Int = 0

    override func layoutSubviews() {
        super.layoutSubviews()

        // 레이아웃이 완료된 후 기간별 일정 렌더링
        renderPeriodEvents()
    }

    // MARK: - Period Event Calculation

    /// 기간별 일정의 행 배치를 계산합니다.
    /// 겹치지 않도록 행을 배정하는 그리디 알고리즘 사용
    private func calculatePeriodEventRows() -> [[PeriodEventLayoutInfo]] {
        var rows: [[PeriodEventLayoutInfo]] = []

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // 기간별 일정 수집 (중복 제거)
        var periodEvents: [(id: UUID, todo: TodoItem, startIndex: Int, endIndex: Int, isFirstSegment: Bool, isLastSegment: Bool)] = []
        var seenIds: Set<UUID> = []

        for dayInfo in weekDays {
            for todo in dayInfo.todos where todo.isPeriodEvent {
                // 이미 처리한 일정 스킵
                if seenIds.contains(todo.id) { continue }
                seenIds.insert(todo.id)

                guard let startDate = todo.startDateObject,
                      let endDate = todo.endDateObject else { continue }

                var startIndex: Int? = nil
                var endIndex: Int? = nil

                // 이 주 내에서의 시작/종료 인덱스 계산
                for (index, day) in weekDays.enumerated() {
                    guard !day.dateString.isEmpty,
                          let dayDate = formatter.date(from: day.dateString) else { continue }

                    let calendar = Calendar.current
                    // startDate의 시작과 endDate의 끝을 사용하여 정확한 비교
                    let dayStart = calendar.startOfDay(for: dayDate)
                    let eventStart = calendar.startOfDay(for: startDate)
                    let eventEnd = calendar.startOfDay(for: endDate)

                    if dayStart >= eventStart && dayStart <= eventEnd {
                        if startIndex == nil { startIndex = index }
                        endIndex = index
                    }
                }

                if let startIdx = startIndex, let endIdx = endIndex {
                    // 이 주에서 시작/종료 여부 확인
                    let isFirstSegment: Bool
                    let isLastSegment: Bool

                    if let firstDayDate = formatter.date(from: weekDays[startIdx].dateString) {
                        let calendar = Calendar.current
                        isFirstSegment = calendar.isDate(firstDayDate, inSameDayAs: startDate)
                    } else {
                        isFirstSegment = false
                    }

                    if let lastDayDate = formatter.date(from: weekDays[endIdx].dateString) {
                        let calendar = Calendar.current
                        isLastSegment = calendar.isDate(lastDayDate, inSameDayAs: endDate)
                    } else {
                        isLastSegment = false
                    }

                    periodEvents.append((
                        id: todo.id,
                        todo: todo,
                        startIndex: startIdx,
                        endIndex: endIdx,
                        isFirstSegment: isFirstSegment,
                        isLastSegment: isLastSegment
                    ))
                }
            }
        }

        // 그리디 알고리즘으로 행 배치
        for event in periodEvents {
            var placed = false

            // 기존 행에 배치 시도
            for (rowIndex, row) in rows.enumerated() {
                var canPlace = true

                // 해당 행의 기존 이벤트들과 겹치는지 확인
                for existingEvent in row {
                    // 범위가 겹치는지 확인
                    if !(event.endIndex < existingEvent.startDayIndex || event.startIndex > existingEvent.endDayIndex) {
                        canPlace = false
                        break
                    }
                }

                if canPlace {
                    let layoutInfo = PeriodEventLayoutInfo(
                        id: event.id,
                        todo: event.todo,
                        startDayIndex: event.startIndex,
                        endDayIndex: event.endIndex,
                        rowIndex: rowIndex,
                        isFirstSegment: event.isFirstSegment,
                        isLastSegment: event.isLastSegment
                    )
                    rows[rowIndex].append(layoutInfo)
                    placed = true
                    break
                }
            }

            // 새 행 추가
            if !placed {
                let layoutInfo = PeriodEventLayoutInfo(
                    id: event.id,
                    todo: event.todo,
                    startDayIndex: event.startIndex,
                    endDayIndex: event.endIndex,
                    rowIndex: rows.count,
                    isFirstSegment: event.isFirstSegment,
                    isLastSegment: event.isLastSegment
                )
                rows.append([layoutInfo])
            }
        }

        return rows
    }

    // MARK: - Period Event Rendering

    /// 기간별 일정을 연속된 바로 렌더링합니다.
    private func renderPeriodEvents() {
        // 기존 뷰 제거
        periodEventViews.forEach { $0.removeFromSuperview() }
        periodEventViews.removeAll()
        moreEventLabel?.removeFromSuperview()
        moreEventLabel = nil

        guard bounds.width > 0 else { return }

        let cellWidth = bounds.width / 7
        let visibleRows = Array(periodEventRows.prefix(maxVisiblePeriodEventRows))

        // 표시 가능한 행까지만 렌더링
        for row in visibleRows {
            for eventInfo in row {
                let overlayView = PeriodEventOverlayView()

                // 프레임 계산
                let startX = CGFloat(eventInfo.startDayIndex) * cellWidth
                let endX = CGFloat(eventInfo.endDayIndex + 1) * cellWidth
                let width = endX - startX
                let y = CGFloat(eventInfo.rowIndex) * (eventHeight + eventSpacing)

                overlayView.frame = CGRect(x: startX, y: y, width: width, height: eventHeight)

                // 설정
                overlayView.configure(
                    todo: eventInfo.todo,
                    isFirstSegment: eventInfo.isFirstSegment,
                    isLastSegment: eventInfo.isLastSegment
                )

                // 탭 제스처 추가
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(periodEventTapped(_:)))
                overlayView.addGestureRecognizer(tapGesture)
                overlayView.tag = eventInfo.todo.id.hashValue
                overlayView.isUserInteractionEnabled = true

                periodEventContainer.addSubview(overlayView)
                periodEventViews.append(overlayView)
            }
        }
        
        // 숨겨진 일정이 있으면 "+N개" 표시 (첫 번째 날짜 열에 표시)
        if hiddenPeriodEventCount > 0 {
            let moreLabel = UILabel()
            moreLabel.text = "+\(hiddenPeriodEventCount)개"
            moreLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            moreLabel.textColor = AppColors.textFieldPlaceholder // 덜 강조되는 색상
            moreLabel.textAlignment = .center
            moreLabel.backgroundColor = .clear // 배경 제거

            // 마지막 행 아래에 표시 (첫 번째 날짜 열)
            let y = CGFloat(visibleRows.count) * (eventHeight + eventSpacing)
            let x: CGFloat = 0
            let width = cellWidth
            moreLabel.frame = CGRect(x: x, y: y, width: width, height: eventHeight)

            periodEventContainer.addSubview(moreLabel)
            moreEventLabel = moreLabel
        }
    }

    @objc private func periodEventTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view as? PeriodEventOverlayView,
              let todo = findTodoById(hashValue: view.tag) else { return }

        // 시작일의 dateString 찾기
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let startDate = todo.startDateObject {
            let dateString = formatter.string(from: startDate)
            onTodoSelected?(todo, dateString)
        }
    }

    private func findTodoById(hashValue: Int) -> TodoItem? {
        for dayInfo in weekDays {
            for todo in dayInfo.todos where todo.id.hashValue == hashValue {
                return todo
            }
        }
        return nil
    }

    // MARK: - Touch Handling
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // 기간별 일정 영역 터치인지 확인
        let periodEventAreaHeight = CGFloat(periodEventRows.count) * (eventHeight + eventSpacing)
        if location.y >= periodEventTopOffset && location.y <= periodEventTopOffset + periodEventAreaHeight {
            // 기간별 일정 영역 터치는 제스처로 처리됨
            return
        }

        // 터치된 위치에 해당하는 DayView 찾기
        let dayWidth = bounds.width / 7
        let dayIndex = Int(location.x / dayWidth)

        guard dayIndex >= 0 && dayIndex < weekDays.count && dayIndex < dayViews.count else { return }

        let dayInfo = weekDays[dayIndex]

        // 빈 날짜가 아니고, 유효한 날짜인 경우에만 선택 처리
        if let _ = dayInfo.day, !dayInfo.dateString.isEmpty {
            onDaySelected?(dayInfo.dateString)
        }
    }
}

/// 주의 각 날짜 정보
struct WeekDayInfo {
    let day: Int? // nil이면 빈 날짜
    let dateString: String // yyyy-MM-dd 형식, 빈 날짜면 ""
    let todos: [TodoItem]
    let isToday: Bool
    let isSelected: Bool
    let holidayName: String?
    let isSunday: Bool
    let isSaturday: Bool
}
