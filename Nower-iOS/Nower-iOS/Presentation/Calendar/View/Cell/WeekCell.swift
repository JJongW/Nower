//
//  WeekCell.swift
//  Nower-iOS
//
//  Created by 신종원 on 1/26/25.
//

import UIKit
import SnapKit

/// 주 단위 셀
final class WeekCell: UICollectionViewCell {
    static let identifier = "WeekCell"
    
    private let weekView: WeekView = {
        let view = WeekView()
        return view
    }()
    
    var onDaySelected: ((String) -> Void)? {
        didSet {
            weekView.onDaySelected = onDaySelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(weekView)
        weekView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func configure(weekDays: [WeekDayInfo]) {
        weekView.configure(weekDays: weekDays)
    }
}
