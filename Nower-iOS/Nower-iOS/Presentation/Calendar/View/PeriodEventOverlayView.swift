//
//  PeriodEventOverlayView.swift
//  Nower-iOS
//
//  Created by AI Assistant on 9/25/25.
//

import UIKit
import SnapKit

/// 기간별 일정을 캘린더에서 연속된 바로 표시하는 뷰
/// WeekView에서 생성되어 여러 날짜에 걸쳐 하나의 연속된 바로 렌더링됩니다.
final class PeriodEventOverlayView: UIView {

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = AppColors.textMain
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        layer.cornerRadius = 6
        layer.masksToBounds = true

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(6)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview().offset(-6)
        }
    }

    // MARK: - Configuration

    /// 기간별 일정을 설정합니다.
    /// - Parameters:
    ///   - todo: 기간별 일정 아이템
    ///   - isFirstSegment: 이 주에서 일정이 시작되는지 여부 (왼쪽 모서리 둥글게)
    ///   - isLastSegment: 이 주에서 일정이 끝나는지 여부 (오른쪽 모서리 둥글게)
    func configure(todo: TodoItem, isFirstSegment: Bool, isLastSegment: Bool) {
        // 배경색 설정
        let eventColor = AppColors.color(for: todo.colorName)
        backgroundColor = eventColor

        // 배경색에 맞춰 텍스트 색상 자동 조정 (WCAG 4.5:1 대비 보장)
        titleLabel.textColor = AppColors.contrastingTextColor(for: eventColor)

        // 제목은 시작 세그먼트에만 표시
        titleLabel.text = isFirstSegment ? todo.text : ""

        // 코너 라운딩 설정
        layer.cornerRadius = 6

        if isFirstSegment && isLastSegment {
            // 단일 주 안에서 시작하고 끝나는 경우: 모든 모서리 둥글게
            layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else if isFirstSegment {
            // 첫 번째 세그먼트: 왼쪽만 둥글게
            layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner
            ]
        } else if isLastSegment {
            // 마지막 세그먼트: 오른쪽만 둥글게
            layer.maskedCorners = [
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            // 중간 세그먼트: 모든 모서리 직각
            layer.cornerRadius = 0
            layer.maskedCorners = []
        }
    }
}
