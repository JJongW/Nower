//
//  DateCell.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit
import SnapKit

final class DateCell: UICollectionViewCell {
    static let identifier = "DateCell"

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

    // 모든 일정용 스택뷰 (기간별 + 단일 날짜)
    // 각 셀 내부에서 모든 일정을 바 형태로 표시합니다.
    private let eventStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2 // design-skills: 8pt 그리드의 0.25배 (2px)
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
        contentView.addSubview(backgroundHighlightView)
        backgroundHighlightView.snp.makeConstraints {
            $0.edges.equalToSuperview() // 마진 제거 - 셀 전체 영역 사용
        }

        backgroundHighlightView.addSubview(dayLabel)
        backgroundHighlightView.addSubview(holidayLabel)
        backgroundHighlightView.addSubview(eventStackView)

        // design-skills: baseUnitPt = 8, minimumVerticalPaddingPt = 8
        // 8pt 그리드 시스템을 따라 spacing 적용
        
        dayLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8) // 8pt 상단 여백
            $0.centerX.equalToSuperview()
            $0.height.equalTo(12)
        }

        holidayLabel.snp.makeConstraints {
            $0.top.equalTo(dayLabel.snp.bottom).offset(4) // 4pt 간격 (8pt 그리드의 절반)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(10).priority(.high) // 공휴일 없을 때는 높이 0
        }

        // 모든 일정 스택뷰 (기간별 + 단일 날짜)
        eventStackView.snp.makeConstraints {
            $0.top.equalTo(holidayLabel.snp.bottom).offset(4) // 4pt 간격
            $0.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview().inset(8) // 8pt 하단 여백
        }
    }

    // MARK: - Configuration
    /// DateCell을 설정합니다.
    /// - Parameters:
    ///   - day: 날짜 (일)
    ///   - todos: 해당 날짜의 모든 일정 (기간별 + 단일 날짜)
    ///   - isToday: 오늘인지 여부
    ///   - isSelected: 선택된 날짜인지 여부
    ///   - dateString: 날짜 문자열 (yyyy-MM-dd)
    ///   - holidayName: 공휴일 이름
    ///   - isSunday: 일요일인지 여부
    ///   - isSaturday: 토요일인지 여부
    func configure(day: Int, todos: [TodoItem], isToday: Bool, isSelected: Bool, dateString: String, holidayName: String?, isSunday: Bool, isSaturday: Bool) {
        dayLabel.text = "\(day)"
        
        // 기존 뷰들 제거
        eventStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        moreLabel.text = ""

        // 기본 색상
        dayLabel.textColor = AppColors.textPrimary

        // 우선순위: 공휴일 > 오늘 > 일요일 > 토요일
        if let holiday = holidayName {
            holidayLabel.text = holiday
            dayLabel.textColor = AppColors.coralred
        } else {
            holidayLabel.text = ""

            if isToday {
                dayLabel.textColor = AppColors.textHighlighted
            } else if isSunday {
                dayLabel.textColor = AppColors.coralred
            } else if isSaturday {
                dayLabel.textColor = AppColors.skyblue
            }
        }

        // MARK: - 모든 일정 표시 (기간별 + 단일 날짜)
        // 각 셀 내부에서 기간별 일정과 단일 일정을 모두 바 형태로 표시합니다.
        let singleDayTodos = todos.filter { !$0.isPeriodEvent }
        let periodTodos = todos.filter { $0.isPeriodEvent }
        
        // 현재 날짜를 Date 객체로 변환
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let currentDate = formatter.date(from: dateString) else { return }
        
        // 셀의 사용 가능한 높이 계산
        // design-skills: 8pt 그리드 시스템, minimumVerticalPaddingPt = 8
        let cellHeight = frame.height > 0 ? frame.height : 80 // 기본 셀 높이 추정
        let topSpace: CGFloat = 8 + 12 + 4 + (holidayName != nil ? 10 : 0) // 상단 여백(8pt) + dayLabel(12px) + 간격(4pt) + holidayLabel
        let eventStackTopOffset: CGFloat = 4 // eventStackView의 top offset
        let bottomPadding: CGFloat = 8 // 하단 여백 8pt
        let availableHeight = cellHeight - topSpace - eventStackTopOffset - bottomPadding
        
        // 각 일정의 높이는 18px + 간격 2px = 20px (첫 번째는 간격 없음)
        let eventHeight: CGFloat = 18
        let eventSpacing: CGFloat = 2
        
        // MARK: - 기간별 일정 표시
        // 기간별 일정은 각 날짜에서 시작/중간/종료 위치를 계산하여 표시
        var allEvents: [(todo: TodoItem, isPeriod: Bool, position: PeriodEventPosition?)] = []
        
        for todo in periodTodos {
            guard let startDate = todo.startDateObject,
                  let endDate = todo.endDateObject else { continue }
            
            // 현재 날짜가 기간 내 어디에 위치하는지 확인
            let position: PeriodEventPosition
            let calendar = Calendar.current
            
            if calendar.isDate(currentDate, inSameDayAs: startDate) && calendar.isDate(currentDate, inSameDayAs: endDate) {
                // 시작일과 종료일이 같은 경우 (단일 날짜)
                position = .single
            } else if calendar.isDate(currentDate, inSameDayAs: startDate) {
                // 시작일
                position = .start
            } else if calendar.isDate(currentDate, inSameDayAs: endDate) {
                // 종료일
                position = .end
            } else {
                // 중간일
                position = .middle
            }
            
            allEvents.append((todo, true, position))
        }
        
        // MARK: - 단일 날짜 일정 추가
        for todo in singleDayTodos {
            allEvents.append((todo, false, nil))
        }
        
        // 사용 가능한 공간에 맞는 최대 일정 개수 계산
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
        
        // "더 보기" 라벨을 위한 공간도 고려
        if allEvents.count > maxVisibleEvents && currentHeight + 18 <= availableHeight {
            maxVisibleEvents = max(0, maxVisibleEvents - 1)
        }
        
        // 계산된 개수만큼 일정 표시
        for (index, eventInfo) in allEvents.prefix(maxVisibleEvents).enumerated() {
            let capsule = EventCapsuleView()
            
            if eventInfo.isPeriod, let position = eventInfo.position {
                // 기간별 일정: 위치에 맞게 스타일 적용 (마진 없음 - 연결된 형태)
                capsule.configurePeriodEvent(
                    title: eventInfo.todo.text,
                    color: AppColors.color(for: eventInfo.todo.colorName),
                    position: position
                )
                
                eventStackView.addArrangedSubview(capsule)
                capsule.snp.makeConstraints {
                    $0.leading.trailing.equalToSuperview() // 기간별 일정은 마진 없음
                }
            } else {
                // 단일 날짜 일정: 기본 스타일 (내부 마진 적용)
                capsule.configure(
                    title: eventInfo.todo.text,
                    color: AppColors.color(for: eventInfo.todo.colorName)
                )
                
                eventStackView.addArrangedSubview(capsule)
                capsule.snp.makeConstraints {
                    // 단일 일정도 마진 없이 셀 전체 너비 사용
                    $0.leading.trailing.equalToSuperview()
                }
            }
        }

        // 남은 일정이 있으면 "더 보기" 표시
        if allEvents.count > maxVisibleEvents {
            let remainingCount = allEvents.count - maxVisibleEvents
            moreLabel.text = "+\(remainingCount)개"
            eventStackView.addArrangedSubview(moreLabel)
        }

        // 선택 상태 배경색 (다크모드 지원)
        backgroundHighlightView.backgroundColor = isSelected ? 
            UIColor { trait in
                if trait.userInterfaceStyle == .dark {
                    return UIColor(white: 1.0, alpha: 0.2) // 다크모드: 밝은 반투명
                } else {
                    return UIColor(white: 0.0, alpha: 0.1) // 라이트모드: 어두운 반투명
                }
            } : .clear
    }
    

    func configureEmpty() {
        dayLabel.text = ""
        holidayLabel.text = ""
        eventStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        backgroundHighlightView.backgroundColor = .clear
    }
}
