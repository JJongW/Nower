//
//  EventTableViewCell.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/20/25.
//

import UIKit

class EventTableViewCell: UITableViewCell {

    private let eventTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "일정"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white // 기본값, configure에서 동적으로 변경됨
        label.numberOfLines = 1
        return label
    }()

    private let eventSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "일상"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white // 기본값, configure에서 동적으로 변경됨
        return label
    }()

    private let containerView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColors.background
        contentView.addSubview(containerView)
        containerView.addSubview(eventTitleLabel)
        containerView.addSubview(eventSubtitleLabel)

        containerView.layer.cornerRadius = 12

        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

        eventTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.trailing.equalToSuperview().inset(12)
        }

        eventSubtitleLabel.snp.makeConstraints {
            $0.top.equalTo(eventTitleLabel.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    func configure(with todo: TodoItem) {
        let backgroundColor = AppColors.color(for: todo.colorName)
        containerView.backgroundColor = backgroundColor
        
        // 배경색에 맞춰 텍스트 색상 자동 조정 (WCAG 4.5:1 대비 보장)
        let textColor = AppColors.contrastingTextColor(for: backgroundColor)
        eventTitleLabel.textColor = textColor
        eventSubtitleLabel.textColor = textColor
        
        eventTitleLabel.text = todo.text
        
        // 기간별 일정인 경우 기간 정보 표시
        if todo.isPeriodEvent, let startDate = todo.startDateObject, let endDate = todo.endDateObject {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            formatter.locale = Locale(identifier: "ko_KR")
            
            let startString = formatter.string(from: startDate)
            let endString = formatter.string(from: endDate)
            
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                eventSubtitleLabel.text = startString
            } else {
                eventSubtitleLabel.text = "\(startString) - \(endString)"
            }
        } else {
            eventSubtitleLabel.text = "일상"
        }
    }
}
