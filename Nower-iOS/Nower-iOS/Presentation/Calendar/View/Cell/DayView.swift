//
//  DayView.swift
//  Nower-iOS
//
//  Created by 신종원 on 1/26/25.
//

import UIKit
import SnapKit

/// 주 내의 단일 날짜를 표시하는 뷰
/// 기간별 일정은 WeekView에서 렌더링되므로, 이 뷰는 단일 날짜 일정만 표시합니다.
final class DayView: UIView {

    /// 날짜키(yyyy-MM-dd) → 밀도 밴드 색 hex 공급자. CalendarViewController가 주입.
    /// 셀 체인(WeekCell→WeekView→DayView)에 시그니처를 늘리지 않으려고 정적 후크 사용.
    static var densityBandHexProvider: ((String) -> String?)?

    // MARK: - Properties
    private var periodEventSlotCount: Int = 0
    private var currentDateString: String = ""
    private var allSingleDayTodos: [TodoItem] = []

    /// "+N개" 라벨 탭 시 호출되는 콜백 (dateString, todos)
    var onMoreTapped: ((String, [TodoItem]) -> Void)?

    // MARK: - Layout Constants
    private let eventHeight: CGFloat = 18
    private let eventSpacing: CGFloat = 2 // 간격 축소 (4 → 2)
    private let periodEventTopOffset: CGFloat = 38 // 공휴일 라벨 공간 포함 (dayLabel 26pt + holidayLabel 10pt = 36pt)

    // MARK: - UI Components

    private let selectedPillView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    /// 오늘 날짜 표시를 위한 원형 배경 뷰
    private let todayCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textHighlighted
        view.layer.cornerRadius = 12 // 24pt 원형
        view.isHidden = true
        return view
    }()

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let holidayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium) // 가독성 향상
        label.textColor = AppColors.coralred
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    private let eventStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4 // 일정 간 간격 4pt (8pt 그리드의 절반)
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.clipsToBounds = false
        stackView.isLayoutMarginsRelativeArrangement = true // layoutMargins 사용 활성화
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2) // 좌우 간격 2pt
        return stackView
    }()

    private let backgroundHighlightView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    /// 밀도 표시 dot (우측 상단) — 전면 배경 대신 작은 점. 보통/과부하만 표시.
    private let densityDotView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()

    private let moreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.textColor = AppColors.textHighlighted
        label.textAlignment = .center
        label.backgroundColor = AppColors.textFieldBackground.withAlphaComponent(0.9)
        label.layer.cornerRadius = 7
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = true
        return label
    }()

    // 기간별 일정 공간을 위한 제약조건 참조
    private var eventStackTopConstraint: Constraint?

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
        clipsToBounds = true

        addSubview(backgroundHighlightView)
        backgroundHighlightView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        backgroundHighlightView.addSubview(selectedPillView)
        backgroundHighlightView.addSubview(todayCircleView)
        backgroundHighlightView.addSubview(dayLabel)
        backgroundHighlightView.addSubview(holidayLabel)
        backgroundHighlightView.addSubview(eventStackView)
        backgroundHighlightView.addSubview(densityDotView)

        densityDotView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(5)
            $0.trailing.equalToSuperview().offset(-5)
            $0.width.height.equalTo(6)
        }

        selectedPillView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(0)
            $0.width.equalTo(38)
            $0.height.equalTo(30)
        }

        todayCircleView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(2)
            $0.width.height.equalTo(24) // 원형 크기
        }

        dayLabel.snp.makeConstraints {
            $0.center.equalTo(todayCircleView) // 원형 중앙에 배치
            $0.height.equalTo(14)
        }

        holidayLabel.snp.makeConstraints {
            $0.top.equalTo(dayLabel.snp.bottom).offset(2) // 축소 (4 → 2)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(8).priority(.high) // 축소 (10 → 8)
        }

        eventStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview().inset(4)
            // superview 기준으로 top 설정 (WeekView의 periodEventTopOffset과 동기화)
            self.eventStackTopConstraint = $0.top.equalToSuperview().offset(periodEventTopOffset).constraint
        }
    }

    // MARK: - Configuration
    /// 날짜 뷰를 설정합니다.
    /// - Parameters:
    ///   - dayInfo: 날짜 정보
    ///   - periodEventSlotCount: WeekView에서 렌더링되는 기간별 일정 행 수 (공간 확보용)
    func configure(with dayInfo: WeekDayInfo, periodEventSlotCount: Int = 0) {
        self.periodEventSlotCount = periodEventSlotCount
        self.currentDateString = dayInfo.dateString

        // 기존 뷰들 제거
        eventStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        moreLabel.text = ""

        // 기간별 일정 공간을 확보하기 위해 eventStackView의 top 제약 업데이트
        // periodEventTopOffset(38) + 기간일정 영역 높이
        let periodEventAreaHeight = CGFloat(periodEventSlotCount) * (eventHeight + eventSpacing)
        let totalOffset = periodEventTopOffset + periodEventAreaHeight

        eventStackTopConstraint?.update(offset: totalOffset)

        // 밀도 히트맵 틴트 (배경)
        applyDensityTint(for: dayInfo.dateString, hasDay: dayInfo.day != nil)

        guard let day = dayInfo.day else {
            // 빈 날짜
            dayLabel.text = ""
            holidayLabel.text = ""
            updateSelectionHighlight(isSelected: false)
            todayCircleView.isHidden = true
            allSingleDayTodos = []
            return
        }

        dayLabel.text = "\(day)"
        dayLabel.textColor = AppColors.textPrimary

        // 오늘 날짜 원형 배경 표시
        todayCircleView.isHidden = !dayInfo.isToday

        if let holiday = dayInfo.holidayName {
            holidayLabel.text = holiday
            if dayInfo.isToday {
                dayLabel.textColor = .white // 원형 배경 위에 흰색 텍스트
            } else {
                dayLabel.textColor = AppColors.coralred
            }
        } else {
            holidayLabel.text = ""

            if dayInfo.isToday {
                dayLabel.textColor = .white // 원형 배경 위에 흰색 텍스트
            } else if dayInfo.isSunday {
                dayLabel.textColor = AppColors.coralred
            } else if dayInfo.isSaturday {
                dayLabel.textColor = AppColors.skyblue
            }
        }

        updateSelectionHighlight(isSelected: dayInfo.isSelected)
        if dayInfo.isSelected {
            dayLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            if !dayInfo.isToday {
                dayLabel.textColor = AppColors.textHighlighted
            }
        } else {
            dayLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        }

        // 단일 날짜 일정만 필터링 (기간별 일정은 WeekView에서 렌더링됨)
        let singleDayTodos = dayInfo.todos.filter { !$0.isPeriodEvent }
        
        // 시간대별로 정렬: 시간이 있는 일정은 시간 순서대로, 하루 종일 일정은 맨 아래에 배치
        let sortedTodos = singleDayTodos.sorted { todo1, todo2 in
            // 둘 다 시간이 있는 경우: 시간 순서대로 정렬
            if let time1 = todo1.scheduledTime, let time2 = todo2.scheduledTime {
                return time1 < time2
            }
            // todo1만 시간이 있는 경우: todo1을 위로
            if todo1.scheduledTime != nil && todo2.scheduledTime == nil {
                return true
            }
            // todo2만 시간이 있는 경우: todo2를 위로
            if todo1.scheduledTime == nil && todo2.scheduledTime != nil {
                return false
            }
            // 둘 다 시간이 없는 경우: 원래 순서 유지 (제목순)
            return todo1.text < todo2.text
        }
        
        allSingleDayTodos = sortedTodos

        guard !sortedTodos.isEmpty else { return }

        // 최대 표시 일정 개수: 3개 (2개 표시 + "+N개" 라벨)
        let maxVisibleEvents = 2
        let shouldShowMore = sortedTodos.count > maxVisibleEvents

        // 단일 일정 표시 (최대 2개, 시간순 정렬됨)
        for todo in sortedTodos.prefix(maxVisibleEvents) {
            let capsule = EventCapsuleView()
            capsule.configure(
                todo: todo,
                color: AppColors.color(for: todo.colorName)
            )
            eventStackView.addArrangedSubview(capsule)
        }

        // 남은 일정 개수 표시 (3개 이상일 때)
        if shouldShowMore {
            let remainingCount = singleDayTodos.count - maxVisibleEvents
            moreLabel.text = "외 \(remainingCount)개"

            // 탭 제스처 추가
            moreLabel.gestureRecognizers?.forEach { moreLabel.removeGestureRecognizer($0) }
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(moreLabelTapped))
            moreLabel.addGestureRecognizer(tapGesture)

            // 눌러볼 수 있음을 명확히 (접근성 + 터치 영역)
            moreLabel.isAccessibilityElement = true
            moreLabel.accessibilityTraits = .button
            moreLabel.accessibilityLabel = "일정 \(remainingCount)개 더 보기"

            eventStackView.addArrangedSubview(moreLabel)
        }
    }

    /// 밀도 표시: 전면 배경 대신 우측 상단 작은 dot (보통/과부하만)
    private func applyDensityTint(for dateString: String, hasDay: Bool) {
        backgroundHighlightView.backgroundColor = .clear
        guard hasDay, let hex = DayView.densityBandHexProvider?(dateString) else {
            densityDotView.isHidden = true
            return
        }
        densityDotView.backgroundColor = DayView.uiColor(densityHex: hex, alpha: 1.0)
        densityDotView.isHidden = false
    }

    private static func uiColor(densityHex hex: String, alpha: CGFloat) -> UIColor {
        let s = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        return UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    @objc private func moreLabelTapped() {
        guard !currentDateString.isEmpty else { return }
        onMoreTapped?(currentDateString, allSingleDayTodos)
    }

    /// 오늘 = 코랄 원(채움), 선택 = 얇은 ring, 둘 다 = 원에 stroke만 (과하지 않게)
    private func updateSelectionHighlight(isSelected: Bool) {
        let isToday = !todayCircleView.isHidden

        if isSelected && isToday {
            // 오늘이면서 선택됨 → 코랄 원 유지 + 흰 stroke만 (pill 없음)
            selectedPillView.isHidden = true
            selectedPillView.backgroundColor = .clear
            selectedPillView.layer.borderWidth = 0
            todayCircleView.layer.borderWidth = 2
            todayCircleView.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        } else if isSelected {
            // 선택만 → 채움 없는 얇은 ring (날짜 주변)
            selectedPillView.isHidden = false
            selectedPillView.backgroundColor = .clear
            selectedPillView.layer.borderWidth = 1.5
            selectedPillView.layer.borderColor = AppColors.textHighlighted.withAlphaComponent(0.7).cgColor
            todayCircleView.layer.borderWidth = 0
        } else {
            // 미선택
            selectedPillView.isHidden = true
            selectedPillView.backgroundColor = .clear
            selectedPillView.layer.borderWidth = 0
            todayCircleView.layer.borderWidth = 0
        }
    }
}
