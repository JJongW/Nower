//
//  ToastView.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/5/25.
//


import UIKit

final class ToastView: UIView {

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    init(message: String) {
        super.init(frame: .zero)
        setupUI(message: message)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(message: String) {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = 20
        clipsToBounds = true

        addSubview(messageLabel)
        messageLabel.text = message
        messageLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }
    }
}
