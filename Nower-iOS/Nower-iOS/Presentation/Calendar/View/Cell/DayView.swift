//
//  DayView.swift
//  Nower-iOS
//
//  Created by 신종원 on 1/26/25.
//

import UIKit
import SnapKit

/// 주 내의 단일 날짜를 표시하는 뷰
final class DayView: UIView {
    
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
        stackView.spacing = 2
        stackView.alignment = .fill
        stackView.distribution = .fill
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
            $0.top.equalTo(holidayLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }
    
    // MARK: - Configuration
    func configure(with dayInfo: WeekDayInfo) {
        // 기존 뷰들 제거
        eventStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        moreLabel.text = ""
        
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
        
        // 일정 표시
        let singleDayTodos = dayInfo.todos.filter { !$0.isPeriodEvent }
        let periodTodos = dayInfo.todos.filter { $0.isPeriodEvent }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let currentDate = formatter.date(from: dayInfo.dateString) else { return }
        
        // 셀의 사용 가능한 높이 계산
        let cellHeight = frame.height > 0 ? frame.height : 80
        let topSpace: CGFloat = 8 + 12 + 4 + (dayInfo.holidayName != nil ? 10 : 0)
        let eventStackTopOffset: CGFloat = 4
        let bottomPadding: CGFloat = 8
        let availableHeight = cellHeight - topSpace - eventStackTopOffset - bottomPadding
        
        let eventHeight: CGFloat = 18
        let eventSpacing: CGFloat = 2
        
        // 기간별 일정과 단일 일정을 모두 포함
        var allEvents: [(todo: TodoItem, isPeriod: Bool, position: PeriodEventPosition?)] = []
        
        // 기간별 일정
        for todo in periodTodos {
            guard let startDate = todo.startDateObject,
                  let endDate = todo.endDateObject else { continue }
            
            let position: PeriodEventPosition
            let calendar = Calendar.current
            
            if calendar.isDate(currentDate, inSameDayAs: startDate) && calendar.isDate(currentDate, inSameDayAs: endDate) {
                position = .single
            } else if calendar.isDate(currentDate, inSameDayAs: startDate) {
                position = .start
            } else if calendar.isDate(currentDate, inSameDayAs: endDate) {
                position = .end
            } else {
                position = .middle
            }
            
            allEvents.append((todo, true, position))
        }
        
        // 단일 날짜 일정
        for todo in singleDayTodos {
            allEvents.append((todo, false, nil))
        }
        
        // 최대 일정 개수 계산
        var maxVisibleEvents = 0
        var currentHeight: CGFloat = 0
        
        for (index, _) in allEvents.enumerated() {
            let heightForThisEvent = (index == 0 ? eventHeight : eventHeight + eventSpacing)
            if currentHeight + heightForThisEvent <= availableHeight {
                maxVisibleEvents += 1
                currentHeight += heightForThisEvent
            } else {
                break
            }
        }
        
        if allEvents.count > maxVisibleEvents && currentHeight + 18 <= availableHeight {
            maxVisibleEvents = max(0, maxVisibleEvents - 1)
        }
        
        // 일정 표시
        for (_, eventInfo) in allEvents.prefix(maxVisibleEvents).enumerated() {
            let capsule = EventCapsuleView()
            
            if eventInfo.isPeriod, let position = eventInfo.position {
                capsule.configurePeriodEvent(
                    title: eventInfo.todo.text,
                    color: AppColors.color(for: eventInfo.todo.colorName),
                    position: position
                )
                
                eventStackView.addArrangedSubview(capsule)
                capsule.snp.makeConstraints {
                    $0.leading.trailing.equalToSuperview()
                }
            } else {
                capsule.configure(
                    title: eventInfo.todo.text,
                    color: AppColors.color(for: eventInfo.todo.colorName)
                )
                
                eventStackView.addArrangedSubview(capsule)
                capsule.snp.makeConstraints {
                    $0.leading.trailing.equalToSuperview()
                }
            }
        }
        
        if allEvents.count > maxVisibleEvents {
            let remainingCount = allEvents.count - maxVisibleEvents
            moreLabel.text = "+\(remainingCount)개"
            eventStackView.addArrangedSubview(moreLabel)
        }
    }
}
