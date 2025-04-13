//
//  EventCapsuleView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//

import UIKit
import SnapKit

class EventCapsuleView: UIView {

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 6

        titleLabel.font = UIFont.systemFont(ofSize: 10)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }

        self.snp.makeConstraints {
            $0.height.equalTo(18)
        }
    }

    func configure(title: String, color: UIColor) {
        titleLabel.text = title
        backgroundColor = color
    }
}
