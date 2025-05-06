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
        contentView.addSubview(backgroundHighlightView)
        backgroundHighlightView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(2)
        }

        backgroundHighlightView.addSubview(dayLabel)
        backgroundHighlightView.addSubview(holidayLabel)
        backgroundHighlightView.addSubview(eventStackView)

        dayLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(2)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(12)
        }

        holidayLabel.snp.makeConstraints {
            $0.top.equalTo(dayLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
        }

        eventStackView.snp.makeConstraints {
            $0.top.equalTo(holidayLabel.snp.bottom).offset(2)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview().inset(2)
        }
    }

    // MARK: - Configuration
    func configure(day: Int, todos: [TodoItem], isToday: Bool, isSelected: Bool, dateString: String, holidayName: String?, isSunday: Bool, isSaturday: Bool) {
        dayLabel.text = "\(day)"
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

        let maxVisibleEvents = 4
        for todo in todos.prefix(maxVisibleEvents) {
            let capsule = EventCapsuleView()
            capsule.configure(title: todo.text, color: AppColors.color(for: todo.colorName))
            eventStackView.addArrangedSubview(capsule)
            capsule.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
            }
        }

        if todos.count > maxVisibleEvents {
            moreLabel.text = "+\(todos.count - maxVisibleEvents)개"
            eventStackView.addArrangedSubview(moreLabel)
        }

        backgroundHighlightView.backgroundColor = isSelected ? UIColor.systemGray4.withAlphaComponent(0.5) : .clear
    }

    func configureEmpty() {
        dayLabel.text = ""
        holidayLabel.text = ""
        eventStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        backgroundHighlightView.backgroundColor = .clear
    }
}
