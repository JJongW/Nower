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

    // MARK: - Layout Constants
    private let eventHeight: CGFloat = 18
    private let eventSpacing: CGFloat = 4

    // MARK: - UI Components
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()

    private let holidayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = AppColors.coralred
        label.textAlignment = .center
        label.numberOfLines = 1
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
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .lightGray
        label.textAlignment = .center
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

        backgroundHighlightView.addSubview(dayLabel)
        backgroundHighlightView.addSubview(holidayLabel)
        backgroundHighlightView.addSubview(eventStackView)

        dayLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(12)
        }

        holidayLabel.snp.makeConstraints {
            $0.top.equalTo(dayLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(10).priority(.high)
        }

        eventStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview().inset(8)
            // 기본 top 제약 - 기간별 일정 슬롯에 따라 동적으로 업데이트됨
            self.eventStackTopConstraint = $0.top.equalTo(holidayLabel.snp.bottom).offset(4).constraint
        }
    }

    // MARK: - Configuration
    /// 날짜 뷰를 설정합니다.
    /// - Parameters:
    ///   - dayInfo: 날짜 정보
    ///   - periodEventSlotCount: WeekView에서 렌더링되는 기간별 일정 행 수 (공간 확보용)
    func configure(with dayInfo: WeekDayInfo, periodEventSlotCount: Int = 0) {
        self.periodEventSlotCount = periodEventSlotCount

        // 기존 뷰들 제거
        eventStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        moreLabel.text = ""

        // 기간별 일정 공간을 확보하기 위해 eventStackView의 top 제약 업데이트
        let periodEventAreaHeight = CGFloat(periodEventSlotCount) * (eventHeight + eventSpacing)
        let baseOffset: CGFloat = 4 // holidayLabel 아래 기본 간격
        let totalOffset = baseOffset + periodEventAreaHeight

        eventStackTopConstraint?.update(offset: totalOffset)

        guard let day = dayInfo.day else {
            // 빈 날짜
            dayLabel.text = ""
            holidayLabel.text = ""
            backgroundHighlightView.backgroundColor = .clear
            return
        }

        dayLabel.text = "\(day)"
        dayLabel.textColor = AppColors.textPrimary

        if let holiday = dayInfo.holidayName {
            holidayLabel.text = holiday
            dayLabel.textColor = AppColors.coralred
        } else {
            holidayLabel.text = ""

            if dayInfo.isToday {
                dayLabel.textColor = AppColors.textHighlighted
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

        guard !singleDayTodos.isEmpty else { return }

        // 셀의 사용 가능한 높이 계산
        let cellHeight = frame.height > 0 ? frame.height : 80
        let topSpace: CGFloat = 8 + 12 + 4 + (dayInfo.holidayName != nil ? 10 : 0)
        let eventStackTopOffset: CGFloat = totalOffset
        let bottomPadding: CGFloat = 8
        let availableHeight = cellHeight - topSpace - eventStackTopOffset - bottomPadding

        // 최대 일정 개수 계산
        var maxVisibleEvents = 0
        var currentHeight: CGFloat = 0

        for (index, _) in singleDayTodos.enumerated() {
            let heightForThisEvent = (index == 0 ? eventHeight : eventHeight + eventSpacing)
            if currentHeight + heightForThisEvent <= availableHeight {
                maxVisibleEvents += 1
                currentHeight += heightForThisEvent
            } else {
                break
            }
        }

        // "+N개" 라벨 공간 확보
        if singleDayTodos.count > maxVisibleEvents && currentHeight + 18 <= availableHeight {
            maxVisibleEvents = max(0, maxVisibleEvents - 1)
        }

        // 단일 일정 표시
        for todo in singleDayTodos.prefix(maxVisibleEvents) {
            let capsule = EventCapsuleView()
            capsule.configure(
                title: todo.text,
                color: AppColors.color(for: todo.colorName)
            )
            eventStackView.addArrangedSubview(capsule)
        }

        // 남은 일정 개수 표시
        if singleDayTodos.count > maxVisibleEvents {
            let remainingCount = singleDayTodos.count - maxVisibleEvents
            moreLabel.text = "+\(remainingCount)개"
            eventStackView.addArrangedSubview(moreLabel)
        }
    }
}
