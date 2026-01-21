//
//  NewEventView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//

import UIKit

final class NewEventView: UIView {

    // MARK: - Components

    let textFieldBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "일정을 입력하세요"
        textField.textColor = AppColors.textPrimary
        textField.setPlaceholder(color: AppColors.textFieldPlaceholder)
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        return textField
    }()

    let colorStackView: UIStackView = {
        var stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 30
        stackView.distribution = .fillEqually
        return stackView
    }()

    let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("추가", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = AppColors.textHighlighted
        button.layer.cornerRadius = 12
        return button
    }()
    
    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("삭제", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor.systemRed
        button.layer.cornerRadius = 12
        return button
    }()

    // MARK: - 기간 선택 관련 컴포넌트
    
    let periodModeContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    let periodModeLabel: UILabel = {
        let label = UILabel()
        label.text = "기간별 일정"
        label.textColor = AppColors.textPrimary
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    let periodModeSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = false
        switchControl.onTintColor = AppColors.color(for: "skyblue")
        return switchControl
    }()
    
    let dateSelectionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.isHidden = true // 기본적으로 숨김
        return view
    }()
    
    let startDateLabel: UILabel = {
        let label = UILabel()
        label.text = "시작일"
        label.textColor = AppColors.textPrimary
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    let startDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("날짜 선택", for: .normal)
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        button.backgroundColor = AppColors.todoBackground
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()
    
    let endDateLabel: UILabel = {
        let label = UILabel()
        label.text = "종료일"
        label.textColor = AppColors.textPrimary
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    let endDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("날짜 선택", for: .normal)
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        button.backgroundColor = AppColors.todoBackground
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()
    
    // MARK: - 기존 컴포넌트들
    
    private(set) var colorOptions: [UIButton] = []
    private(set) var selectedColorName: String = "skyblue"
    let colorNames: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]
    
    // MARK: - 기간 선택 관련 프로퍼티
    
    var isPeriodMode: Bool = false {
        didSet {
            updateDateSelectionVisibility()
        }
    }
    
    var selectedStartDate: Date?
    var selectedEndDate: Date?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        backgroundColor = AppColors.popupBackground

        // 텍스트 필드
        addSubview(textFieldBackgroundView)
        addSubview(textField)

        // design-skills: 8pt 그리드 시스템
        textFieldBackgroundView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24) // 8pt 그리드 (24 = 3 * 8)
            $0.height.equalTo(56) // 최소 터치 타겟 44pt + 패딩
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        textField.snp.makeConstraints {
            $0.center.equalTo(textFieldBackgroundView)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        // 기간 모드 스위치
        addSubview(periodModeContainer)
        periodModeContainer.addSubview(periodModeLabel)
        periodModeContainer.addSubview(periodModeSwitch)

        periodModeContainer.snp.makeConstraints {
            $0.top.equalTo(textFieldBackgroundView.snp.bottom).offset(16) // 8pt 그리드 (16 = 2 * 8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(56) // 최소 터치 타겟 44pt + 패딩
        }

        periodModeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        periodModeSwitch.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        // 날짜 선택 컨테이너
        addSubview(dateSelectionContainer)
        setupDateSelectionContainer()

        dateSelectionContainer.snp.makeConstraints {
            $0.top.equalTo(periodModeContainer.snp.bottom).offset(12) // 8pt 그리드 근사값
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(100)
        }

        // 색상 선택
        addSubview(colorStackView)
        colorStackView.snp.makeConstraints {
            $0.top.equalTo(dateSelectionContainer.snp.bottom).offset(24) // 8pt 그리드 (24 = 3 * 8)
            $0.leading.trailing.equalToSuperview().inset(32)
            $0.height.equalTo(40)
        }

        for color in colorNames {
            let button = UIButton()
            button.backgroundColor = AppColors.color(for: color)
            button.layer.cornerRadius = 20
            button.layer.borderColor = AppColors.textHighlighted.cgColor
            button.layer.borderWidth = 1
            button.tag = colorOptions.count
            colorOptions.append(button)
            colorStackView.addArrangedSubview(button)
        }

        // 저장/삭제 버튼 컨테이너 (가로로 나란히 배치)
        let buttonStackView: UIStackView = {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stack.spacing = 12 // 8pt 그리드 근사값 (12 = 1.5 * 8)
            stack.alignment = .fill
            return stack
        }()
        
        addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.addArrangedSubview(deleteButton)
        
        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(colorStackView.snp.bottom).offset(32) // 8pt 그리드 (32 = 4 * 8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52) // 최소 터치 타겟 44pt + 패딩
        }
        
        // 각 버튼의 높이 제약
        saveButton.snp.makeConstraints {
            $0.height.equalTo(52)
        }
        
        deleteButton.snp.makeConstraints {
            $0.height.equalTo(52)
        }
        
        deleteButton.isHidden = true
        
        // 스위치 액션 설정
        periodModeSwitch.addTarget(self, action: #selector(periodModeSwitchChanged(_:)), for: .valueChanged)
        startDateButton.addTarget(self, action: #selector(startDateButtonTapped), for: .touchUpInside)
        endDateButton.addTarget(self, action: #selector(endDateButtonTapped), for: .touchUpInside)
    }
    
    private func setupDateSelectionContainer() {
        dateSelectionContainer.addSubview(startDateLabel)
        dateSelectionContainer.addSubview(startDateButton)
        dateSelectionContainer.addSubview(endDateLabel)
        dateSelectionContainer.addSubview(endDateButton)
        
        startDateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
        }
        
        startDateButton.snp.makeConstraints {
            $0.top.equalTo(startDateLabel.snp.bottom).offset(8) // 8pt 그리드
            $0.leading.equalToSuperview().offset(16)
            $0.width.equalTo(130)
            $0.height.equalTo(44) // 최소 터치 타겟 44pt
        }
        
        endDateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-16)
        }
        
        endDateButton.snp.makeConstraints {
            $0.top.equalTo(endDateLabel.snp.bottom).offset(8) // 8pt 그리드
            $0.trailing.equalToSuperview().offset(-16)
            $0.width.equalTo(130)
            $0.height.equalTo(44) // 최소 터치 타겟 44pt
        }
    }

    // MARK: - Actions
    
    @objc private func periodModeSwitchChanged(_ sender: UISwitch) {
        isPeriodMode = sender.isOn
    }
    
    @objc private func startDateButtonTapped() {
        showDatePicker(for: .start)
    }
    
    @objc private func endDateButtonTapped() {
        showDatePicker(for: .end)
    }
    
    // MARK: - Helper Methods
    
    private func updateDateSelectionVisibility() {
        UIView.animate(withDuration: 0.3) {
            self.dateSelectionContainer.isHidden = !self.isPeriodMode
        }
    }
    
    private enum DatePickerType {
        case start, end
    }
    
    private func showDatePicker(for type: DatePickerType) {
        guard let parentViewController = findViewController() else { return }
        
        // 커스텀 DatePicker 뷰컨트롤러 생성
        let datePickerVC = UIViewController()
        datePickerVC.preferredContentSize = CGSize(width: 320, height: 300)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "ko_KR")
        
        // 최소/최대 날짜 설정
        if type == .end, let startDate = selectedStartDate {
            datePicker.minimumDate = startDate
        }
        if type == .start, let endDate = selectedEndDate {
            datePicker.maximumDate = endDate
        }
        
        datePickerVC.view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: datePickerVC.view.centerXAnchor),
            datePicker.centerYAnchor.constraint(equalTo: datePickerVC.view.centerYAnchor)
        ])
        
        let alert = UIAlertController(title: type == .start ? "시작일 선택" : "종료일 선택", 
                                    message: nil, 
                                    preferredStyle: .actionSheet)
        
        alert.setValue(datePickerVC, forKey: "contentViewController")
        
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            let selectedDate = datePicker.date
            self.updateSelectedDate(selectedDate, for: type)
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad에서 actionSheet를 위한 설정
        if let popover = alert.popoverPresentationController {
            if type == .start {
                popover.sourceView = self.startDateButton
                popover.sourceRect = self.startDateButton.bounds
            } else {
                popover.sourceView = self.endDateButton
                popover.sourceRect = self.endDateButton.bounds
            }
        }
        
        parentViewController.present(alert, animated: true)
    }
    
    private func updateSelectedDate(_ date: Date, for type: DatePickerType) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        formatter.locale = Locale(identifier: "ko_KR")
        
        switch type {
        case .start:
            selectedStartDate = date
            startDateButton.setTitle(formatter.string(from: date), for: .normal)
        case .end:
            selectedEndDate = date
            endDateButton.setTitle(formatter.string(from: date), for: .normal)
        }
    }
    
    func selectColor(_ sender: UIButton) {
        for (index, button) in colorOptions.enumerated() {
            button.layer.borderWidth = (button == sender) ? 3 : 0
            if button == sender {
                selectedColorName = colorNames[index]
            }
        }
    }
    
    /// 기간 모드 설정 (외부에서 호출)
    func setPeriodMode(_ enabled: Bool, startDate: Date? = nil, endDate: Date? = nil) {
        isPeriodMode = enabled
        periodModeSwitch.isOn = enabled
        
        if let startDate = startDate {
            selectedStartDate = startDate
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            startDateButton.setTitle(formatter.string(from: startDate), for: .normal)
        }
        
        if let endDate = endDate {
            selectedEndDate = endDate
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            endDateButton.setTitle(formatter.string(from: endDate), for: .normal)
        }
    }
}

// MARK: - UIView Extension
extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
