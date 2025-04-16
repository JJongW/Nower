//
//  EventCell.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//

import UIKit
import SnapKit

class EventCell: UITableViewCell {

    static let identifier = "EventCell"

    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = AppColors.textPrimary

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
