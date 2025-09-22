//
//  EventCapsuleView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//

import UIKit
import SnapKit

class EventCapsuleView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = AppColors.textMain
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = false
        label.minimumScaleFactor = 1.0
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.layer.cornerRadius = 6

        addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(3)
        }

        self.snp.makeConstraints {
            $0.height.equalTo(18) // 높이를 줄여서 더 자연스러운 간격
        }
    }

    func configure(title: String, color: UIColor) {
        titleLabel.text = title
        backgroundColor = color
        // 기본 스타일 (단일 날짜 일정)
        layer.cornerRadius = 6
    }
    
    /// 기간별 일정을 위한 설정 메서드
    /// - Parameters:
    ///   - title: 일정 제목 (시작일이 아닌 경우 빈 문자열)
    ///   - color: 배경색
    ///   - position: 기간 내에서의 위치 (시작/중간/종료/단일)
    func configurePeriodEvent(title: String, color: UIColor, position: PeriodEventPosition) {
        // 제목은 시작일에만 표시, 나머지는 빈 공간으로 표시
        switch position {
        case .start:
            titleLabel.text = title
        case .middle, .end:
            titleLabel.text = "" // 중간일과 종료일에는 제목 표시 안함
        case .single:
            titleLabel.text = title
        }
        
        backgroundColor = color
        
        switch position {
        case .start:
            // 시작일: 왼쪽은 둥글게, 오른쪽은 직각
            layer.cornerRadius = 9
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        case .middle:
            // 중간일: 모든 모서리 직각 (완전히 연결된 느낌)
            layer.cornerRadius = 0
            layer.maskedCorners = []
        case .end:
            // 종료일: 오른쪽은 둥글게, 왼쪽은 직각
            layer.cornerRadius = 9
            layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        case .single:
            // 단일 날짜: 모든 모서리 둥글게 (기본)
            layer.cornerRadius = 9
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, 
                                  .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
    }
}

/// 기간별 일정에서의 위치를 나타내는 열거형
enum PeriodEventPosition {
    case start      // 시작일
    case middle     // 중간일
    case end        // 종료일
    case single     // 단일 날짜 (기간이 아닌 일정)
}
