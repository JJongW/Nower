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

    private let recurrenceIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.2.squarepath")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.isHidden = true
        return imageView
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
        containerView.addSubview(recurrenceIconView)
        containerView.addSubview(eventSubtitleLabel)

        containerView.layer.cornerRadius = 12

        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

        eventTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.equalToSuperview().offset(12)
        }

        recurrenceIconView.snp.makeConstraints {
            $0.centerY.equalTo(eventTitleLabel)
            $0.leading.equalTo(eventTitleLabel.snp.trailing).offset(4)
            $0.trailing.lessThanOrEqualToSuperview().offset(-12)
            $0.size.equalTo(14)
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
        recurrenceIconView.tintColor = textColor

        eventTitleLabel.text = todo.text

        // 반복 아이콘 표시
        recurrenceIconView.isHidden = !todo.isRecurringEvent

        // 서브타이틀 구성
        var subtitleParts: [String] = []

        // 반복 정보 표시
        if let info = todo.recurrenceInfo {
            subtitleParts.append(info.displayString)
        }

        // 시간 정보 표시
        if todo.isPeriodEvent, let startDate = todo.startDateObject, let endDate = todo.endDateObject {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            formatter.locale = Locale(identifier: "ko_KR")

            var startString = formatter.string(from: startDate)
            var endString = formatter.string(from: endDate)

            if let startTime = todo.scheduledTime {
                startString += " \(startTime)"
            }
            if let endTime = todo.endScheduledTime {
                endString += " \(endTime)"
            }

            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                subtitleParts.append(startString)
            } else {
                subtitleParts.append("\(startString) ~ \(endString)")
            }
        } else {
            if let time = todo.scheduledTime {
                let parts = time.split(separator: ":")
                if parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) {
                    let period = hour < 12 ? "오전" : "오후"
                    let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                    subtitleParts.append(String(format: "%@ %d:%02d", period, displayHour, minute))
                } else {
                    subtitleParts.append(time)
                }
            } else {
                subtitleParts.append("종일")
            }
        }

        eventSubtitleLabel.text = subtitleParts.joined(separator: " · ")
    }
}
