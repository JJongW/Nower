//
//  CalendarView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit
import SnapKit

class CalendarView: UIView {

    let monthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.text = "2025.4"
        label.textAlignment = .center
        label.textColor = AppColors.textPrimary
        return label
    }()
    let previousButton = UIButton(type: .system)
    let nextButton = UIButton(type: .system)
    let collectionView: UICollectionView

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 8

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white

        previousButton.setTitle("<", for: .normal)
        nextButton.setTitle(">", for: .normal)

        addSubview(previousButton)
        addSubview(monthLabel)
        addSubview(nextButton)
        addSubview(collectionView)

        monthLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(16)
            $0.centerX.equalToSuperview()
        }
        previousButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.width.height.equalTo(32)
        }

        nextButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.width.height.equalTo(32)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(monthLabel.snp.bottom).offset(36)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        collectionView.backgroundColor = .white
        collectionView.register(DateCell.self, forCellWithReuseIdentifier: DateCell.identifier)
    }
}
