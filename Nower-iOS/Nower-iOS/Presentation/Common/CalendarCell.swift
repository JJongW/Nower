//
//  CalendarCell.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit
import SnapKit

class CalendarCell: UICollectionViewCell {
    static let identifier = "CalendarCell"

    private let backgroundCircleView = UIView()
    private let dayLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(backgroundCircleView)
        backgroundCircleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(36)
        }
        backgroundCircleView.layer.cornerRadius = 18
        backgroundCircleView.backgroundColor = .clear

        dayLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        dayLabel.textAlignment = .center
        dayLabel.textColor = .label

        contentView.addSubview(dayLabel)
        dayLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func configure(day: Int) {
        dayLabel.text = "\(day)"
        reset()
    }

    func configureEmpty() {
        dayLabel.text = ""
        backgroundCircleView.backgroundColor = .clear
    }

    func highlightToday() {
        backgroundCircleView.backgroundColor = .systemBlue
        dayLabel.textColor = .white
    }

    func highlightSelected() {
        backgroundCircleView.backgroundColor = .systemGray3
        dayLabel.textColor = .label
    }

    func reset() {
        backgroundCircleView.backgroundColor = .clear
        dayLabel.textColor = .label
    }
}
