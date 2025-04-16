//
//  DateCell.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//

import UIKit
import SnapKit

class DateCell: UICollectionViewCell {
    static let identifier = "DateCell"

    let dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()
    let eventStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()
    private let backgroundHighlightView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundHighlightView.backgroundColor = .clear

        addSubview(backgroundHighlightView)
        backgroundHighlightView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.width.equalToSuperview()
        }

        backgroundHighlightView.addSubview(dayLabel)
        backgroundHighlightView.addSubview(eventStackView)

        dayLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(2)
            $0.height.equalTo(12)
            $0.centerX.equalToSuperview()
        }

        eventStackView.snp.makeConstraints {
            $0.top.equalTo(dayLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview().offset(-2)
        }
    }

    func configure(day: Int, todos: [TodoItem], isToday: Bool, isSelected: Bool) {
        dayLabel.text = "\(day)"
        eventStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let maxVisibleEvents = 4
        let limitedEvents = todos.prefix(maxVisibleEvents)

        for todo in limitedEvents {
            let capsule = EventCapsuleView()
            capsule.configure(title: todo.text, color: AppColors.color(for: todo.colorName))
            eventStackView.addArrangedSubview(capsule)

            capsule.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(2)
            }
        }

        if todos.count > maxVisibleEvents {
            let moreLabel = UILabel()
            moreLabel.text = "+\(todos.count - maxVisibleEvents)개"
            moreLabel.font = UIFont.systemFont(ofSize: 10)
            moreLabel.textColor = .lightGray
            eventStackView.addArrangedSubview(moreLabel)
        }

        backgroundHighlightView.backgroundColor = .clear
        backgroundHighlightView.layer.borderWidth = 0
        dayLabel.textColor = AppColors.textPrimary

        if isToday {
            dayLabel.textColor = .systemBlue
        }

        if isSelected {
            backgroundHighlightView.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.5)
        }
    }

    func configureEmpty() {
        dayLabel.text = ""
        backgroundHighlightView.backgroundColor = .clear
        backgroundHighlightView.layer.borderWidth = 0
        eventStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
