//
//  ColorVariationPickerView.swift
//  Nower-iOS
//
//  Created by AI Assistant on 2026/01/25.
//

import UIKit

/// 색상 variation 선택을 위한 팝업 뷰
final class ColorVariationPickerView: UIView {
    
    // MARK: - Properties
    
    var onColorSelected: ((String) -> Void)? // 색상 선택 콜백 (예: "skyblue-3")
    private let baseColorName: String
    private var variationButtons: [UIButton] = []
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.popupBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.2
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "색상 톤 선택"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()
    
    private let colorStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()
    
    // MARK: - Init
    
    init(baseColorName: String, frame: CGRect = .zero) {
        self.baseColorName = baseColorName
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(colorStackView)
        
        // 8가지 톤 버튼 생성
        let buttonSize: CGFloat = 32 // 원형 버튼 크기 (레이아웃 충돌 방지)
        let buttonSpacing: CGFloat = 6 // 버튼 간 간격
        
        // 필요한 너비 계산: 8개 버튼 + 7개 간격 + 좌우 패딩
        let totalWidth = (buttonSize * 8) + (buttonSpacing * 7) + 32 // 좌우 패딩 16pt씩
        
        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(totalWidth)
            $0.height.equalTo(120)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        colorStackView.spacing = buttonSpacing
        colorStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-16)
            $0.height.equalTo(buttonSize) // 버튼 높이 고정
        }
        let tones = AppColors.colorTones(for: baseColorName)
        for (index, color) in tones.enumerated() {
            let button = UIButton()
            button.backgroundColor = color
            button.layer.cornerRadius = buttonSize / 2 // 완전한 원형
            button.tag = index + 1 // 1-8
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            variationButtons.append(button)
            colorStackView.addArrangedSubview(button)
            
            // 정사각형으로 고정하여 원형 유지
            button.snp.makeConstraints {
                $0.width.height.equalTo(buttonSize)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func colorButtonTapped(_ sender: UIButton) {
        let colorName = "\(baseColorName)-\(sender.tag)"
        onColorSelected?(colorName)
        removeFromSuperview()
    }
    
    // MARK: - Public Methods
    
    /// 현재 선택된 색상에 맞게 테두리 표시
    func highlightTone(_ tone: Int?) {
        for (index, button) in variationButtons.enumerated() {
            let isSelected = (index + 1) == tone
            if isSelected {
                // 선택된 색상의 테두리: 다크모드면 흰색, 라이트모드면 검정색
                let borderColor = UIColor { trait in
                    if trait.userInterfaceStyle == .dark {
                        return UIColor.white
                    } else {
                        return UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0) // #0F0F0F
                    }
                }
                button.layer.borderColor = borderColor.cgColor
                button.layer.borderWidth = 2.5
            } else {
                button.layer.borderWidth = 0
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 배경 터치 시 닫기
        if let touch = touches.first, touch.view == self {
            removeFromSuperview()
        }
    }
}
