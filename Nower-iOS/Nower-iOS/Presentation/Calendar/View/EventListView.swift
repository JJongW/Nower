//
//  EventListView.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/24/25.
//

import UIKit


final class EventListView: UIView {

    let eventDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = AppColors.textPrimary
        return label
    }()

    let eventWeekLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .light)
        label.textColor = AppColors.textPrimary
        return label
    }()

    let eventLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColors.textFieldPlaceholder
        label.textAlignment = .center
        label.text = "" // 동적으로 설정
        return label
    }()

    // 상태 캡션 (탭 동작 없음 — 추가는 플로팅 + 버튼이 담당).
    // 강조색/세미볼드는 링크처럼 보여 오해를 줘 회색 캡션으로 강등 (UX 검토 P1/P2).
    let modeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = AppColors.textFieldPlaceholder
        label.textAlignment = .right
        return label
    }()

    let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "아직 일정이 없어요\n아래 + 버튼으로 이 날짜에 추가할 수 있어요"
        label.isHidden = true
        return label
    }()

    private let dateStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()

    let eventTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppColors.background
        tableView.register(EventTableViewCell.self, forCellReuseIdentifier: "EventCell")
        return tableView
    }()

    let addButton: UIButton = {
        let button = UIButton()
        button.setTitle("＋", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 32, weight: .bold)
        // 강조 색상으로 변경하여 더 잘 보이게
        button.backgroundColor = AppColors.textHighlighted
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 28
        // 그림자 추가로 더 눈에 띄게
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.3
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColors.background

        addSubview(eventTableView)
        addSubview(addButton)

        dateStack.addArrangedSubview(eventDateLabel)
        dateStack.addArrangedSubview(eventWeekLabel)

        addSubview(dateStack)
        addSubview(eventLabel)
        addSubview(modeLabel)
        addSubview(emptyStateLabel)

        dateStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        eventLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(dateStack)
            $0.leading.greaterThanOrEqualTo(dateStack.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(modeLabel.snp.leading).offset(-12)
        }

        modeLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalTo(dateStack)
        }

        eventTableView.snp.makeConstraints {
            $0.top.equalTo(dateStack.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyStateLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(eventTableView.snp.centerY).offset(-20)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(56) // 더 크게 (최소 터치 타겟 44pt + 여유)
        }

        addButton.accessibilityLabel = "새 일정 추가"
    }

    func configure(date: Date, eventCount: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M월 d일"

        modeLabel.text = eventCount == 0 ? "일정 없음" : "일정 \(eventCount)개"
        emptyStateLabel.isHidden = eventCount > 0
        eventTableView.isHidden = eventCount == 0
        addButton.accessibilityHint = "\(dateFormatter.string(from: date))에 일정을 추가합니다"
    }
}
