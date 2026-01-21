//
//  EventDotView.swift
//  Nower-iOS
//
//  Created by AI Assistant on 1/26/25.
//

import UIKit
import SnapKit

/// 단일 날짜 일정을 작은 점(dot)과 텍스트로 표시하는 뷰
/// 이미지 예시처럼 "● Team Meeting" 형태로 표시됩니다.
final class EventDotView: UIView {
    
    // MARK: - UI Components
    
    private let dotView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3 // 작은 원형 점
        view.clipsToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        label.textColor = AppColors.textMain
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(dotView)
        addSubview(titleLabel)
        
        dotView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(2)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(6) // 작은 원형 점 크기
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(dotView.snp.trailing).offset(4) // 점과 텍스트 사이 간격
            $0.trailing.lessThanOrEqualToSuperview().offset(-2)
            $0.centerY.equalToSuperview()
        }
        
        // 전체 뷰 높이 설정
        self.snp.makeConstraints {
            $0.height.equalTo(14) // 점과 텍스트를 포함한 높이
        }
    }
    
    // MARK: - Configuration
    
    /// 이벤트 점 뷰를 설정합니다.
    /// - Parameters:
    ///   - title: 일정 제목
    ///   - color: 점의 색상
    func configure(title: String, color: UIColor) {
        dotView.backgroundColor = color
        titleLabel.text = title
    }
}
