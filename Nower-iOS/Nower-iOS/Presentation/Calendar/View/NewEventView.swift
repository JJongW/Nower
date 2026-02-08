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

    private let colorHintLabel: UILabel = {
        let label = UILabel()
        label.text = "꾹 눌러 색상 톤 선택"
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = AppColors.textFieldPlaceholder
        label.textAlignment = .center
        return label
    }()

    let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("추가", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = AppColors.textHighlighted
        button.layer.cornerRadius = 12
        button.isEnabled = false
        button.alpha = 0.4
        return button
    }()
    
    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("삭제", for: .normal)
        button.setTitleColor(UIColor.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.systemRed.cgColor
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
    
    // MARK: - 시간/알림 설정 컴포넌트

    let timeSettingContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    private let timeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_time")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = AppColors.coralred
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private(set) var timeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "시간"
        label.textColor = AppColors.textPrimary
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    let timeValueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("하루 종일", for: .normal)
        button.setTitleColor(AppColors.textHighlighted, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()

    // MARK: - 종료 시간 설정 컴포넌트 (기간별 일정용)

    let endTimeSettingContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()

    private let endTimeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_time")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = AppColors.coralred
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let endTimeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "종료 시간"
        label.textColor = AppColors.textPrimary
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    let endTimeValueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("하루 종일", for: .normal)
        button.setTitleColor(AppColors.textHighlighted, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()

    let reminderSettingContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    private let reminderIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_alarm")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = AppColors.coralred
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let reminderTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "알림"
        label.textColor = AppColors.textPrimary
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    let reminderValueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("없음", for: .normal)
        button.setTitleColor(AppColors.textHighlighted, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()

    // MARK: - 기존 컴포넌트들

    private(set) var colorOptions: [UIButton] = []
    var selectedColorName: String = "skyblue-4" { // 기본값을 중간 톤으로 설정
        didSet {
            updateColorSelection()
        }
    }
    let colorNames: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]
    private var colorVariationPicker: ColorVariationPickerView?
    
    // MARK: - 기간 선택 관련 프로퍼티

    var isPeriodMode: Bool = false {
        didSet {
            guard !isSettingPeriodMode else { return }
            updateDateSelectionVisibility()
            // 기간 모드 활성화 시 기본 날짜 자동 설정
            if isPeriodMode && selectedStartDate == nil {
                let defaultDate = initialSelectedDate ?? Date()
                selectedStartDate = defaultDate
                selectedEndDate = defaultDate
                updateDateButtonTitles()
            }
        }
    }

    var selectedStartDate: Date?
    var selectedEndDate: Date?

    /// 외부에서 주입받은 선택된 날짜 (기간 모드 기본값용)
    var initialSelectedDate: Date?

    /// 날짜 선택 컨테이너 높이/여백 제약 (접었다 펼치기용)
    private var dateContainerHeightConstraint: NSLayoutConstraint?
    private var dateContainerTopConstraint: NSLayoutConstraint?
    /// 종료 시간 컨테이너 높이/여백 제약 (접었다 펼치기용)
    private var endTimeContainerHeightConstraint: NSLayoutConstraint?
    private var endTimeContainerTopConstraint: NSLayoutConstraint?
    /// setPeriodMode에서 애니메이션 없이 설정 중일 때 didSet 중복 실행 방지
    private var isSettingPeriodMode = false

    // MARK: - 시간/알림 프로퍼티

    var selectedScheduledTime: String? {
        didSet { updateTimeDisplay() }
    }

    var selectedEndScheduledTime: String? {
        didSet { updateEndTimeDisplay() }
    }

    var selectedReminderMinutesBefore: Int? {
        didSet { updateReminderDisplay() }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupKeyboardObservers()
        setupDismissKeyboardGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Scroll View

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private let contentView = UIView()

    // MARK: - UI Setup

    private func setupUI() {
        backgroundColor = AppColors.popupBackground

        // 스크롤뷰 설정
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // 텍스트 필드
        contentView.addSubview(textFieldBackgroundView)
        contentView.addSubview(textField)

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
        contentView.addSubview(periodModeContainer)
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
        contentView.addSubview(dateSelectionContainer)
        setupDateSelectionContainer()

        // 높이/여백을 NSLayoutConstraint로 직접 관리 (접기/펼치기용)
        dateSelectionContainer.translatesAutoresizingMaskIntoConstraints = false
        let topC = dateSelectionContainer.topAnchor.constraint(equalTo: periodModeContainer.bottomAnchor, constant: 0)
        let heightC = dateSelectionContainer.heightAnchor.constraint(equalToConstant: 0)
        topC.isActive = true
        heightC.isActive = true
        dateContainerTopConstraint = topC
        dateContainerHeightConstraint = heightC
        dateSelectionContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 시간 설정 행
        contentView.addSubview(timeSettingContainer)
        timeSettingContainer.addSubview(timeIconView)
        timeSettingContainer.addSubview(timeTitleLabel)
        timeSettingContainer.addSubview(timeValueButton)

        timeSettingContainer.snp.makeConstraints {
            $0.top.equalTo(dateSelectionContainer.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }

        timeIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        timeTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(timeIconView.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        timeValueButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        // 종료 시간 설정 행 (기간별 일정용) — 높이/여백을 NSLayoutConstraint로 관리 (접기/펼치기용)
        contentView.addSubview(endTimeSettingContainer)
        endTimeSettingContainer.addSubview(endTimeIconView)
        endTimeSettingContainer.addSubview(endTimeTitleLabel)
        endTimeSettingContainer.addSubview(endTimeValueButton)

        endTimeSettingContainer.translatesAutoresizingMaskIntoConstraints = false
        let endTimeTopC = endTimeSettingContainer.topAnchor.constraint(equalTo: timeSettingContainer.bottomAnchor, constant: 0)
        let endTimeHeightC = endTimeSettingContainer.heightAnchor.constraint(equalToConstant: 0)
        endTimeTopC.isActive = true
        endTimeHeightC.isActive = true
        endTimeContainerTopConstraint = endTimeTopC
        endTimeContainerHeightConstraint = endTimeHeightC
        endTimeSettingContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        endTimeIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        endTimeTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(endTimeIconView.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        endTimeValueButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        // 알림 설정 행
        contentView.addSubview(reminderSettingContainer)
        reminderSettingContainer.addSubview(reminderIconView)
        reminderSettingContainer.addSubview(reminderTitleLabel)
        reminderSettingContainer.addSubview(reminderValueButton)

        reminderSettingContainer.snp.makeConstraints {
            $0.top.equalTo(endTimeSettingContainer.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }

        reminderIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        reminderTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(reminderIconView.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        reminderValueButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        // 시간 미설정 시 알림 행 비활성화
        updateReminderEnabled()

        // 색상 선택
        contentView.addSubview(colorStackView)
        contentView.addSubview(colorHintLabel)

        colorStackView.snp.makeConstraints {
            $0.top.equalTo(reminderSettingContainer.snp.bottom).offset(24) // 8pt 그리드 (24 = 3 * 8)
            $0.leading.trailing.equalToSuperview().inset(32)
            $0.height.equalTo(40)
        }

        colorHintLabel.snp.makeConstraints {
            $0.top.equalTo(colorStackView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }

        for color in colorNames {
            let button = UIButton()
            // 기본 색상의 중간 톤(4)을 기본값으로 표시
            button.backgroundColor = AppColors.color(for: "\(color)-4")
            button.layer.cornerRadius = 20
            button.tag = colorOptions.count
            colorOptions.append(button)
            colorStackView.addArrangedSubview(button)

            // 한 번 탭: 기본 톤(4)으로 선택만 (팝업 없이)
            button.addTarget(self, action: #selector(colorButtonSingleTapped(_:)), for: .touchUpInside)

            // 꾹 누르기(0.3초): 톤 선택 팝업 표시
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(colorButtonLongPressed(_:)))
            longPress.minimumPressDuration = 0.3
            button.addGestureRecognizer(longPress)

            // 더블 탭: 톤 선택 팝업 표시
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(colorButtonDoubleTapped(_:)))
            doubleTap.numberOfTapsRequired = 2
            button.addGestureRecognizer(doubleTap)

            // 색상 버튼 눌림 효과
            button.addPressAnimation()
        }

        // 초기 선택 상태 업데이트
        updateColorSelection()

        // 저장/삭제 버튼 컨테이너 (가로로 나란히 배치)
        let buttonStackView: UIStackView = {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.distribution = .fill // 수정 버튼이 더 넓게
            stack.spacing = 12 // 8pt 그리드 근사값 (12 = 1.5 * 8)
            stack.alignment = .fill
            return stack
        }()

        contentView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.addArrangedSubview(deleteButton)

        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(colorHintLabel.snp.bottom).offset(24) // 8pt 그리드 (24 = 3 * 8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52) // 최소 터치 타겟 44pt + 패딩
            $0.bottom.equalToSuperview().offset(-24) // 스크롤 콘텐츠 하단 여백
        }

        // 수정 버튼이 삭제 버튼보다 2배 넓게
        saveButton.snp.makeConstraints {
            $0.height.equalTo(52)
            $0.width.equalTo(deleteButton).multipliedBy(2)
        }

        deleteButton.snp.makeConstraints {
            $0.height.equalTo(52)
        }

        deleteButton.isHidden = true

        // 스위치 액션 설정
        periodModeSwitch.addTarget(self, action: #selector(periodModeSwitchChanged(_:)), for: .valueChanged)
        startDateButton.addTarget(self, action: #selector(startDateButtonTapped), for: .touchUpInside)
        endDateButton.addTarget(self, action: #selector(endDateButtonTapped), for: .touchUpInside)

        // 시간/알림 버튼 액션
        timeValueButton.addTarget(self, action: #selector(timeValueButtonTapped), for: .touchUpInside)
        endTimeValueButton.addTarget(self, action: #selector(endTimeValueButtonTapped), for: .touchUpInside)
        reminderValueButton.addTarget(self, action: #selector(reminderValueButtonTapped), for: .touchUpInside)

        // 버튼 눌림 효과 적용
        saveButton.addPressAnimation()
        deleteButton.addPressAnimation()
        startDateButton.addPressAnimation()
        endDateButton.addPressAnimation()
        timeValueButton.addPressAnimation()
        endTimeValueButton.addPressAnimation()
        reminderValueButton.addPressAnimation()

        // 텍스트 필드 변경 감지 → 저장 버튼 활성화/비활성화
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // 접근성 설정
        setupAccessibility()
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        // 텍스트 필드
        textField.accessibilityLabel = "일정 이름"
        textField.accessibilityHint = "일정 이름을 입력하세요"

        // 기간 모드 스위치
        periodModeSwitch.accessibilityLabel = "기간별 일정"
        periodModeSwitch.accessibilityHint = "활성화하면 여러 날에 걸친 일정을 만들 수 있습니다"

        // 날짜 버튼
        startDateButton.accessibilityLabel = "시작일"
        startDateButton.accessibilityHint = "탭하여 시작 날짜를 선택하세요"
        endDateButton.accessibilityLabel = "종료일"
        endDateButton.accessibilityHint = "탭하여 종료 날짜를 선택하세요"

        // 색상 버튼
        let colorLabels = ["하늘색", "피치", "라벤더", "민트그린", "코랄레드"]
        for (index, button) in colorOptions.enumerated() {
            button.accessibilityLabel = "\(colorLabels[index]) 색상"
            button.accessibilityHint = "탭하여 선택, 꾹 눌러 색상 톤을 선택하세요"
        }

        // 시간/알림 버튼
        timeValueButton.accessibilityLabel = "시간 설정"
        timeValueButton.accessibilityHint = "탭하여 일정 시간을 설정하세요"
        endTimeValueButton.accessibilityLabel = "종료 시간 설정"
        endTimeValueButton.accessibilityHint = "탭하여 종료 시간을 설정하세요"
        reminderValueButton.accessibilityLabel = "알림 설정"
        reminderValueButton.accessibilityHint = "탭하여 알림을 설정하세요"

        // 저장/삭제 버튼
        saveButton.accessibilityLabel = "저장"
        saveButton.accessibilityHint = "일정을 저장합니다"
        deleteButton.accessibilityLabel = "삭제"
        deleteButton.accessibilityHint = "일정을 삭제합니다"
    }
    
    // MARK: - Keyboard Handling

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupDismissKeyboardGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        endEditing(true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        let keyboardHeight = keyboardFrame.height
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = keyboardHeight
            self.scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        }

        // 텍스트 필드가 가려지지 않도록 스크롤
        let textFieldBottom = textFieldBackgroundView.convert(textFieldBackgroundView.bounds, to: scrollView).maxY + 16
        let visibleHeight = scrollView.bounds.height - keyboardHeight
        if textFieldBottom > scrollView.contentOffset.y + visibleHeight {
            let offset = CGPoint(x: 0, y: textFieldBottom - visibleHeight)
            scrollView.setContentOffset(offset, animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    private func setupDateSelectionContainer() {
        // 화살표 아이콘 추가
        let arrowLabel = UILabel()
        arrowLabel.text = "→"
        arrowLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        arrowLabel.textColor = AppColors.textFieldPlaceholder
        arrowLabel.textAlignment = .center

        dateSelectionContainer.addSubview(startDateLabel)
        dateSelectionContainer.addSubview(startDateButton)
        dateSelectionContainer.addSubview(arrowLabel)
        dateSelectionContainer.addSubview(endDateLabel)
        dateSelectionContainer.addSubview(endDateButton)

        startDateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
        }

        startDateButton.snp.makeConstraints {
            $0.top.equalTo(startDateLabel.snp.bottom).offset(8) // 8pt 그리드
            $0.leading.equalToSuperview().offset(16)
            $0.width.greaterThanOrEqualTo(100) // 최소 너비
            $0.height.equalTo(44) // 최소 터치 타겟 44pt
        }

        arrowLabel.snp.makeConstraints {
            $0.centerY.equalTo(startDateButton)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(24)
        }

        endDateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-16)
        }

        endDateButton.snp.makeConstraints {
            $0.top.equalTo(endDateLabel.snp.bottom).offset(8) // 8pt 그리드
            $0.trailing.equalToSuperview().offset(-16)
            $0.width.greaterThanOrEqualTo(100) // 최소 너비
            $0.height.equalTo(44) // 최소 터치 타겟 44pt
        }

        // 버튼 내부 패딩 설정
        startDateButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        endDateButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
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
        if isPeriodMode {
            // 펼치기
            dateSelectionContainer.isHidden = false
            dateSelectionContainer.alpha = 0
            dateContainerHeightConstraint?.constant = 100
            dateContainerTopConstraint?.constant = 12

            endTimeSettingContainer.isHidden = false
            endTimeSettingContainer.alpha = 0
            endTimeContainerHeightConstraint?.constant = 52
            endTimeContainerTopConstraint?.constant = 8

            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut]
            ) {
                self.dateSelectionContainer.alpha = 1
                self.endTimeSettingContainer.alpha = 1
                self.timeTitleLabel.text = "시작 시간"
                self.layoutIfNeeded()
            }
        } else {
            // 접기 — 높이와 여백을 0으로 축소
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0,
                options: [.curveEaseIn]
            ) {
                self.dateSelectionContainer.alpha = 0
                self.dateContainerHeightConstraint?.constant = 0
                self.dateContainerTopConstraint?.constant = 0
                self.endTimeSettingContainer.alpha = 0
                self.endTimeContainerHeightConstraint?.constant = 0
                self.endTimeContainerTopConstraint?.constant = 0
                self.timeTitleLabel.text = "시간"
                self.layoutIfNeeded()
            } completion: { _ in
                self.dateSelectionContainer.isHidden = true
                self.endTimeSettingContainer.isHidden = true
            }
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
        switch type {
        case .start:
            selectedStartDate = date
        case .end:
            selectedEndDate = date
        }
        updateDateButtonTitles()
    }

    private func updateDateButtonTitles() {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")

        if let startDate = selectedStartDate {
            startDateButton.setTitle(formatter.string(from: startDate), for: .normal)
        } else {
            startDateButton.setTitle("날짜 선택", for: .normal)
        }

        if let endDate = selectedEndDate {
            endDateButton.setTitle(formatter.string(from: endDate), for: .normal)
        } else {
            endDateButton.setTitle("날짜 선택", for: .normal)
        }
    }
    
    // MARK: - 시간/알림 Actions

    @objc private func timeValueButtonTapped() {
        guard let parentView = findViewController()?.view else { return }
        let picker = TimePickerView(currentTime: selectedScheduledTime)
        picker.onTimeSelected = { [weak self] time in
            self?.selectedScheduledTime = time
            self?.updateReminderEnabled()
            // 시간을 해제하면 알림도 해제
            if time == nil {
                self?.selectedReminderMinutesBefore = nil
            }
        }
        parentView.addSubview(picker)
        picker.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @objc private func endTimeValueButtonTapped() {
        guard let parentView = findViewController()?.view else { return }
        let picker = TimePickerView(currentTime: selectedEndScheduledTime)
        picker.onTimeSelected = { [weak self] time in
            self?.selectedEndScheduledTime = time
        }
        parentView.addSubview(picker)
        picker.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @objc private func reminderValueButtonTapped() {
        guard selectedScheduledTime != nil else { return }
        guard let parentView = findViewController()?.view else { return }
        let picker = ReminderPickerView(currentMinutes: selectedReminderMinutesBefore)
        picker.onReminderSelected = { [weak self] minutes in
            self?.selectedReminderMinutesBefore = minutes
        }
        parentView.addSubview(picker)
        picker.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - 시간/알림 Display Helpers

    private func updateTimeDisplay() {
        if let time = selectedScheduledTime {
            // "HH:mm" → 오전/오후 표시
            let parts = time.split(separator: ":")
            if parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) {
                let period = hour < 12 ? "오전" : "오후"
                let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                timeValueButton.setTitle(String(format: "%@ %d:%02d", period, displayHour, minute), for: .normal)
            } else {
                timeValueButton.setTitle(time, for: .normal)
            }
        } else {
            timeValueButton.setTitle("하루 종일", for: .normal)
        }
    }

    private func updateEndTimeDisplay() {
        if let time = selectedEndScheduledTime {
            let parts = time.split(separator: ":")
            if parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) {
                let period = hour < 12 ? "오전" : "오후"
                let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                endTimeValueButton.setTitle(String(format: "%@ %d:%02d", period, displayHour, minute), for: .normal)
            } else {
                endTimeValueButton.setTitle(time, for: .normal)
            }
        } else {
            endTimeValueButton.setTitle("하루 종일", for: .normal)
        }
    }

    private func updateReminderDisplay() {
        guard let minutes = selectedReminderMinutesBefore else {
            reminderValueButton.setTitle("없음", for: .normal)
            return
        }
        switch minutes {
        case 0: reminderValueButton.setTitle("정시", for: .normal)
        case 5: reminderValueButton.setTitle("5분 전", for: .normal)
        case 10: reminderValueButton.setTitle("10분 전", for: .normal)
        case 30: reminderValueButton.setTitle("30분 전", for: .normal)
        case 60: reminderValueButton.setTitle("1시간 전", for: .normal)
        case 1440: reminderValueButton.setTitle("1일 전", for: .normal)
        default: reminderValueButton.setTitle("\(minutes)분 전", for: .normal)
        }
    }

    private func updateReminderEnabled() {
        let enabled = selectedScheduledTime != nil
        reminderSettingContainer.alpha = enabled ? 1.0 : 0.4
        reminderValueButton.isEnabled = enabled
    }

    // MARK: - Color Selection

    /// 한 번 탭: 기본 톤(4)으로 색상 선택 (팝업 없이)
    @objc private func colorButtonSingleTapped(_ sender: UIButton) {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        let baseColorName = colorNames[sender.tag]
        selectedColorName = "\(baseColorName)-4"
    }

    /// 꾹 누르기: 톤 선택 팝업 표시
    @objc private func colorButtonLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let button = gesture.view as? UIButton else { return }

        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        let baseColorName = colorNames[button.tag]
        showColorVariationPicker(for: baseColorName, sourceButton: button)
    }

    /// 더블 탭: 톤 선택 팝업 표시
    @objc private func colorButtonDoubleTapped(_ gesture: UITapGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }

        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        let baseColorName = colorNames[button.tag]
        showColorVariationPicker(for: baseColorName, sourceButton: button)
    }
    
    private func showColorVariationPicker(for baseColorName: String, sourceButton: UIButton) {
        // 기존 picker 제거
        colorVariationPicker?.removeFromSuperview()
        
        // 새 picker 생성
        let picker = ColorVariationPickerView(baseColorName: baseColorName)
        picker.onColorSelected = { [weak self] colorName in
            self?.selectedColorName = colorName
            self?.updateColorSelection()
        }
        
        // 현재 선택된 색상이 이 baseColorName인 경우 톤 하이라이트
        let currentBaseName = AppColors.baseColorName(from: selectedColorName)
        if currentBaseName == baseColorName {
            let tone = AppColors.toneNumber(from: selectedColorName)
            picker.highlightTone(tone)
        }
        
        colorVariationPicker = picker
        
        // 부모 뷰에 추가
        guard let parentView = findViewController()?.view else { return }
        parentView.addSubview(picker)
        picker.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func updateColorSelection(animated: Bool = true) {
        let selectedBaseName = AppColors.baseColorName(from: selectedColorName)

        for (index, button) in colorOptions.enumerated() {
            let baseName = colorNames[index]
            let isSelected = baseName == selectedBaseName

            let updateBlock = {
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
                    button.layer.borderWidth = 3

                    // 선택된 톤으로 색상 업데이트
                    let tone = AppColors.toneNumber(from: self.selectedColorName) ?? 4
                    button.backgroundColor = AppColors.color(for: "\(baseName)-\(tone)")

                    // 선택 시 살짝 확대
                    button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                } else {
                    button.layer.borderWidth = 0
                    // 선택되지 않은 색상은 중간 톤(4)으로 표시
                    button.backgroundColor = AppColors.color(for: "\(baseName)-4")
                    button.transform = .identity
                }
            }

            if animated {
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    usingSpringWithDamping: 0.7,
                    initialSpringVelocity: 0.5,
                    options: [.curveEaseOut]
                ) {
                    updateBlock()
                }
            } else {
                updateBlock()
            }
        }
    }
    
    func selectColor(_ sender: UIButton) {
        // 기존 메서드 호환성 유지
        let baseColorName = colorNames[sender.tag]
        selectedColorName = "\(baseColorName)-4"
        updateColorSelection()
    }
    
    /// 기간 모드 설정 (외부에서 호출)
    func setPeriodMode(_ enabled: Bool, startDate: Date? = nil, endDate: Date? = nil) {
        if let startDate = startDate {
            selectedStartDate = startDate
        }
        if let endDate = endDate {
            selectedEndDate = endDate
        }

        // 애니메이션 없이 즉시 제약 반영 (초기 설정용)
        isSettingPeriodMode = true
        if enabled {
            dateSelectionContainer.isHidden = false
            dateSelectionContainer.alpha = 1
            dateContainerHeightConstraint?.constant = 100
            dateContainerTopConstraint?.constant = 12
            endTimeSettingContainer.isHidden = false
            endTimeSettingContainer.alpha = 1
            endTimeContainerHeightConstraint?.constant = 52
            endTimeContainerTopConstraint?.constant = 8
            timeTitleLabel.text = "시작 시간"
        } else {
            dateSelectionContainer.isHidden = true
            dateSelectionContainer.alpha = 0
            dateContainerHeightConstraint?.constant = 0
            dateContainerTopConstraint?.constant = 0
            endTimeSettingContainer.isHidden = true
            endTimeSettingContainer.alpha = 0
            endTimeContainerHeightConstraint?.constant = 0
            endTimeContainerTopConstraint?.constant = 0
            timeTitleLabel.text = "시간"
        }
        periodModeSwitch.isOn = enabled
        isPeriodMode = enabled
        isSettingPeriodMode = false
        updateDateButtonTitles()
        layoutIfNeeded()
    }

    /// 선택된 날짜 설정 (새 일정 추가 시 외부에서 호출)
    func setInitialSelectedDate(_ date: Date) {
        initialSelectedDate = date
    }

    // MARK: - Save Button State

    @objc private func textFieldDidChange() {
        updateSaveButtonState()
    }

    func updateSaveButtonState() {
        let hasText = !(textField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        saveButton.isEnabled = hasText
        UIView.animate(withDuration: 0.2) {
            self.saveButton.alpha = hasText ? 1.0 : 0.4
        }
    }

    // MARK: - Error Feedback

    /// 텍스트 필드 에러 시 흔들림 애니메이션 표시
    func shakeTextField() {
        // 햅틱 피드백
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)

        // 흔들림 애니메이션
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-10, 10, -8, 8, -5, 5, -2, 2, 0]
        textFieldBackgroundView.layer.add(animation, forKey: "shake")

        // 테두리 색상 변경 (잠시 빨간색)
        let originalBorderWidth = textFieldBackgroundView.layer.borderWidth
        let originalBorderColor = textFieldBackgroundView.layer.borderColor

        textFieldBackgroundView.layer.borderWidth = 1.5
        textFieldBackgroundView.layer.borderColor = UIColor.systemRed.cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIView.animate(withDuration: 0.3) {
                self.textFieldBackgroundView.layer.borderWidth = originalBorderWidth
                self.textFieldBackgroundView.layer.borderColor = originalBorderColor
            }
        }
    }

    /// 저장 성공 시 햅틱 피드백
    func triggerSuccessFeedback() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
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

// MARK: - UIButton Extension for Press Animation
extension UIButton {
    /// 버튼 눌림 효과 애니메이션 추가
    func addPressAnimation() {
        addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func buttonPressed() {
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.curveEaseIn, .allowUserInteraction]
        ) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.alpha = 0.9
        }
    }

    @objc private func buttonReleased() {
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }
}
