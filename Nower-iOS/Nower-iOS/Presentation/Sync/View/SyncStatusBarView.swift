//
//  SyncStatusBarView.swift
//  Nower-iOS
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import UIKit

final class SyncStatusBarView: UIView {

    // MARK: - UI Components

    let iconButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .systemGray
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: "icloud", withConfiguration: config), for: .normal)
        button.accessibilityLabel = "동기화 상태"
        return button
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()

    // MARK: - Animation

    private var rotationAnimation: CABasicAnimation?
    private var syncStartTime: Date?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        // Task #1: Start hidden (idle state)
        alpha = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(iconButton)
        addSubview(badgeLabel)

        iconButton.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconButton.topAnchor.constraint(equalTo: topAnchor),
            iconButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            iconButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            iconButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            iconButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            badgeLabel.heightAnchor.constraint(equalToConstant: 16),
            badgeLabel.topAnchor.constraint(equalTo: iconButton.topAnchor, constant: 2),
            badgeLabel.trailingAnchor.constraint(equalTo: iconButton.trailingAnchor, constant: 2),
        ])
    }

    // MARK: - Update

    func update(iconName: String, color: UIColor, animate: Bool, accessibilityLabel: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        iconButton.tintColor = color
        iconButton.accessibilityLabel = accessibilityLabel

        if animate {
            syncStartTime = syncStartTime ?? Date()
            startRotation()
        } else {
            // Task #6: Skip fast sync animation — don't animate out if sync was < 0.5s
            if let start = syncStartTime, Date().timeIntervalSince(start) < 0.5 {
                stopRotation()
            } else {
                stopRotation()
            }
            syncStartTime = nil
        }
    }

    // MARK: - Visibility (Task #1)

    func setVisible(_ visible: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.alpha = visible ? 1 : 0
            }
        } else {
            alpha = visible ? 1 : 0
        }
    }

    // MARK: - Badge (Task #5)

    func updateBadge(count: Int) {
        if count > 0 {
            badgeLabel.text = "\(count)"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }

    // MARK: - Rotation Animation

    private func startRotation() {
        guard iconButton.layer.animation(forKey: "syncRotation") == nil else { return }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = 1.5
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        iconButton.layer.add(animation, forKey: "syncRotation")
    }

    private func stopRotation() {
        iconButton.layer.removeAnimation(forKey: "syncRotation")
    }
}
