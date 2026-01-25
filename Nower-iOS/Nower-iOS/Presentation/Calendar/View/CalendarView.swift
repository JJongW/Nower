//
//  CalendarView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit
import SnapKit

final class CalendarView: UIView {

    let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = AppColors.textPrimary
        return label
    }()

    let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium) // 축소 (12 → 11)
        label.textAlignment = .left
        label.text = DailyQuoteManager.getTodayQuote()
        label.textColor = AppColors.textFieldPlaceholder // 덜 강조
        label.numberOfLines = 1 // 한 줄로 제한
        return label
    }()

    let previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("<", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.tintColor = AppColors.textHighlighted
        return button
    }()

    let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(">", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.tintColor = AppColors.textHighlighted
        return button
    }()

    private let weekdayStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 0
        return stack
    }()

    let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0 // 셀 간격 제거
        layout.minimumLineSpacing = 0 // 행 간격 제거
        layout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = AppColors.background
        collectionView.register(WeekCell.self, forCellWithReuseIdentifier: WeekCell.identifier)
        collectionView.isScrollEnabled = false // 스크롤 비활성화 (한 화면에 모두 표시)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.clipsToBounds = true // 가장자리 클리핑으로 겹침 방지
        return collectionView
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
        clipsToBounds = true // 부모 뷰도 클리핑 설정으로 겹침 방지

        addSubview(monthLabel)
        addSubview(previousButton)
        addSubview(nextButton)
        addSubview(textLabel)
        addSubview(weekdayStackView)
        addSubview(collectionView)

        for (index, day) in weekdays.enumerated() {
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)

            if index == 0 {
                label.textColor = AppColors.coralred
            } else if index == 6 {
                label.textColor = AppColors.skyblue
            } else {
                label.textColor = AppColors.textPrimary
            }

            weekdayStackView.addArrangedSubview(label)
        }

        monthLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(8) // 축소 (16 → 8)
            $0.centerX.equalToSuperview()
        }

        previousButton.snp.makeConstraints {
            $0.centerY.equalTo(monthLabel)
            $0.leading.equalToSuperview().offset(20)
        }

        nextButton.snp.makeConstraints {
            $0.centerY.equalTo(monthLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        textLabel.snp.makeConstraints {
            $0.top.equalTo(monthLabel.snp.bottom).offset(12) // 축소 (48 → 12)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }

        weekdayStackView.snp.makeConstraints {
            $0.top.equalTo(textLabel.snp.bottom).offset(16) // 축소 (36 → 16)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.height.equalTo(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(weekdayStackView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
    }
}
