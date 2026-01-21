//
//  WeekView.swift
//  Nower-iOS
//
//  Created by 신종원 on 1/26/25.
//

import UIKit
import SnapKit

/// 한 주를 표시하는 뷰
/// 7개의 날짜를 가로로 배치하고, 각 날짜의 일정들을 표시합니다.
final class WeekView: UIView {
    
    // MARK: - Properties
    private var dayViews: [DayView] = []
    private var weekDays: [WeekDayInfo] = []
    var onDaySelected: ((String) -> Void)? // 날짜 선택 콜백 (dateString 전달)
    
    // MARK: - UI Components
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
        addSubview(dayContainerStackView)
        dayContainerStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 7개의 DayView 생성
        for _ in 0..<7 {
            let dayView = DayView()
            dayViews.append(dayView)
            dayContainerStackView.addArrangedSubview(dayView)
        }
    }
    
    // MARK: - Configuration
    /// 주 뷰를 설정합니다.
    /// - Parameter weekDays: 7개의 날짜 정보 (빈 날짜 포함 가능)
    func configure(weekDays: [WeekDayInfo]) {
        self.weekDays = weekDays
        for (index, dayInfo) in weekDays.enumerated() {
            guard index < dayViews.count else { break }
            dayViews[index].configure(with: dayInfo)
        }
    }
    
    // MARK: - Touch Handling
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // 터치된 위치에 해당하는 DayView 찾기
        let dayWidth = bounds.width / 7
        let dayIndex = Int(location.x / dayWidth)
        
        guard dayIndex >= 0 && dayIndex < weekDays.count && dayIndex < dayViews.count else { return }
        
        let dayInfo = weekDays[dayIndex]
        
        // 빈 날짜가 아니고, 유효한 날짜인 경우에만 선택 처리
        if let day = dayInfo.day, !dayInfo.dateString.isEmpty {
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
