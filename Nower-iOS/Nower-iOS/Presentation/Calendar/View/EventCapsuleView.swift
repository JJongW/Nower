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

        // 기본 패딩 설정 (기간별 일정에서는 다르게 설정됨)
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
        // 배경색에 맞춰 텍스트 색상 자동 조정 (WCAG 4.5:1 대비 보장)
        titleLabel.textColor = AppColors.contrastingTextColor(for: color)
        // 기본 스타일 (단일 날짜 일정)
        layer.cornerRadius = 6
    }
    
    /// 기간별 일정을 위한 설정 메서드
    /// - Parameters:
    ///   - title: 일정 제목 (시작일이 아닌 경우 빈 문자열)
    ///   - color: 배경색
    ///   - position: 기간 내에서의 위치 (시작/중간/종료/단일)
    func configurePeriodEvent(title: String, color: UIColor, position: PeriodEventPosition) {
        backgroundColor = color
        // 배경색에 맞춰 텍스트 색상 자동 조정 (WCAG 4.5:1 대비 보장)
        titleLabel.textColor = AppColors.contrastingTextColor(for: color)
        
        // 제목은 시작일에만 표시, 나머지는 빈 공간으로 표시
        switch position {
        case .start:
            titleLabel.text = title
            // 시작일: 텍스트를 위해 좌측 패딩만 유지, 우측은 0으로
            titleLabel.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview()
                $0.leading.equalToSuperview().offset(6) // 좌측만 패딩
                $0.trailing.equalToSuperview() // 우측은 가장자리까지
            }
        case .middle, .end:
            titleLabel.text = "" // 중간일과 종료일에는 제목 표시 안함
            // 중간일/종료일: 패딩 완전 제거 - 셀 가장자리에 붙도록
            titleLabel.snp.remakeConstraints {
                $0.edges.equalToSuperview() // 패딩 없음
            }
        case .single:
            titleLabel.text = title
            // 단일일: 기본 패딩 유지
            titleLabel.snp.remakeConstraints {
                $0.edges.equalToSuperview().inset(3)
            }
        }
        
        switch position {
        case .start:
            // 시작일: 왼쪽은 둥글게, 오른쪽은 직각
            layer.cornerRadius = 6
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        case .middle:
            // 중간일: 모든 모서리 직각 (완전히 연결된 느낌)
            layer.cornerRadius = 0
            layer.maskedCorners = []
        case .end:
            // 종료일: 오른쪽은 둥글게, 왼쪽은 직각
            layer.cornerRadius = 6
            layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        case .single:
            // 단일 날짜: 모든 모서리 둥글게 (기본)
            layer.cornerRadius = 6
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
