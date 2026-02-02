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

    private let moreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = AppColors.textFieldPlaceholder // 덜 강조되는 색상
        label.textAlignment = .center
        label.backgroundColor = .clear // 배경 제거
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
        clipsToBounds = false

        addSubview(backgroundHighlightView)
        backgroundHighlightView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        backgroundHighlightView.addSubview(todayCircleView)
        backgroundHighlightView.addSubview(dayLabel)
        backgroundHighlightView.addSubview(holidayLabel)
        backgroundHighlightView.addSubview(eventStackView)

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

        guard let day = dayInfo.day else {
            // 빈 날짜
            dayLabel.text = ""
            holidayLabel.text = ""
            backgroundHighlightView.backgroundColor = .clear
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

        // 선택 상태 배경색 (다크모드 지원)
        backgroundHighlightView.backgroundColor = dayInfo.isSelected ?
            UIColor { trait in
                if trait.userInterfaceStyle == .dark {
                    return UIColor(white: 1.0, alpha: 0.2) // 다크모드: 밝은 반투명
                } else {
                    return UIColor(white: 0.0, alpha: 0.1) // 라이트모드: 어두운 반투명
                }
            } : .clear

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
                title: todo.text,
                color: AppColors.color(for: todo.colorName),
                time: todo.scheduledTime
            )
            eventStackView.addArrangedSubview(capsule)
        }

        // 남은 일정 개수 표시 (3개 이상일 때)
        if shouldShowMore {
            let remainingCount = singleDayTodos.count - maxVisibleEvents
            moreLabel.text = "+\(remainingCount)개"

            // 탭 제스처 추가
            moreLabel.gestureRecognizers?.forEach { moreLabel.removeGestureRecognizer($0) }
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(moreLabelTapped))
            moreLabel.addGestureRecognizer(tapGesture)

            eventStackView.addArrangedSubview(moreLabel)
        }
    }

    @objc private func moreLabelTapped() {
        guard !currentDateString.isEmpty else { return }
        onMoreTapped?(currentDateString, allSingleDayTodos)
    }
}
