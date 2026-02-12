//
//  CustomRecurrenceViewController.swift
//  Nower-iOS
//
//  Apple 캘린더 스타일의 고급 반복 설정 시트
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import UIKit
import SnapKit

final class CustomRecurrenceViewController: UIViewController {

    // MARK: - Callback

    var onRecurrenceSelected: ((RecurrenceInfo?) -> Void)?

    // MARK: - State

    private var selectedFrequency: String = "weekly"
    private var selectedInterval: Int = 1
    private var selectedDaysOfWeek: Set<Int> = []
    private var selectedDayOfMonth: Int? = nil
    private var endCondition: EndCondition = .never
    private var endDate: Date? = nil
    private var endAfterCount: Int = 10

    private enum EndCondition {
        case never, afterCount, onDate
    }

    /// 기존 RecurrenceInfo로 초기화
    var initialInfo: RecurrenceInfo?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "사용자 설정 반복"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    // 빈도 선택
    private lazy var frequencySegment: UISegmentedControl = {
        let items = ["매일", "매주", "매월", "매년"]
        let seg = UISegmentedControl(items: items)
        seg.selectedSegmentIndex = 1 // 기본: 매주
        seg.addTarget(self, action: #selector(frequencyChanged(_:)), for: .valueChanged)
        return seg
    }()

    // 간격 설정
    private let intervalLabel: UILabel = {
        let label = UILabel()
        label.text = "1주마다"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var intervalStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.maximumValue = 99
        stepper.value = 1
        stepper.addTarget(self, action: #selector(intervalChanged(_:)), for: .valueChanged)
        return stepper
    }()

    // 요일 선택 컨테이너 (주간 반복 시만 표시)
    private let weekdayContainer: UIView = {
        let view = UIView()
        return view
    }()

    private let weekdayLabel: UILabel = {
        let label = UILabel()
        label.text = "요일 선택"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColors.textFieldPlaceholder
        return label
    }()

    private let weekdayStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        return stack
    }()

    private var weekdayButtons: [UIButton] = []
    private let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]

    // 종료 조건
    private let endConditionLabel: UILabel = {
        let label = UILabel()
        label.text = "종료"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private lazy var endConditionSegment: UISegmentedControl = {
        let items = ["안 함", "횟수", "날짜"]
        let seg = UISegmentedControl(items: items)
        seg.selectedSegmentIndex = 0
        seg.addTarget(self, action: #selector(endConditionChanged(_:)), for: .valueChanged)
        return seg
    }()

    // 횟수 종료 컨테이너
    private let countContainer: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.text = "10회 후 종료"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var countStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.maximumValue = 999
        stepper.value = 10
        stepper.addTarget(self, action: #selector(countChanged(_:)), for: .valueChanged)
        return stepper
    }()

    // 날짜 종료 컨테이너
    private let dateContainer: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private lazy var endDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ko_KR")
        picker.minimumDate = Date()
        picker.addTarget(self, action: #selector(endDateChanged(_:)), for: .valueChanged)
        return picker
    }()

    // 액션 버튼
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("완료", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = AppColors.textHighlighted
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.addPressAnimation()
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        button.addPressAnimation()
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.popupBackground
        setupUI()
        restoreInitialInfo()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // 타이틀
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 빈도 선택
        let frequencyContainer = createSectionContainer()
        contentView.addSubview(frequencyContainer)
        frequencyContainer.addSubview(frequencySegment)

        frequencyContainer.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        frequencySegment.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
            $0.height.equalTo(32)
        }

        // 간격 설정
        let intervalContainer = createSectionContainer()
        contentView.addSubview(intervalContainer)
        intervalContainer.addSubview(intervalLabel)
        intervalContainer.addSubview(intervalStepper)

        intervalContainer.snp.makeConstraints {
            $0.top.equalTo(frequencyContainer.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }

        intervalLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        intervalStepper.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        // 요일 선택
        contentView.addSubview(weekdayContainer)
        weekdayContainer.addSubview(weekdayLabel)
        weekdayContainer.addSubview(weekdayStackView)

        weekdayContainer.snp.makeConstraints {
            $0.top.equalTo(intervalContainer.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        weekdayLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(4)
        }

        weekdayStackView.snp.makeConstraints {
            $0.top.equalTo(weekdayLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview()
        }

        for i in 0..<7 {
            let button = UIButton(type: .system)
            button.setTitle(weekdayNames[i], for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            button.layer.cornerRadius = 22
            button.layer.masksToBounds = true
            button.tag = i + 1 // 1=일..7=토
            button.addTarget(self, action: #selector(weekdayTapped(_:)), for: .touchUpInside)
            updateWeekdayButton(button, selected: false)
            weekdayButtons.append(button)
            weekdayStackView.addArrangedSubview(button)

            // 접근성
            button.accessibilityLabel = "\(weekdayNames[i])요일"
            button.accessibilityHint = "탭하여 선택/해제"
        }

        // 종료 조건
        let endSectionLabel = createSectionContainer()
        contentView.addSubview(endSectionLabel)
        endSectionLabel.addSubview(endConditionLabel)
        endSectionLabel.addSubview(endConditionSegment)

        endSectionLabel.snp.makeConstraints {
            $0.top.equalTo(weekdayContainer.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        endConditionLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }

        endConditionSegment.snp.makeConstraints {
            $0.top.equalTo(endConditionLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(32)
            $0.bottom.equalToSuperview().offset(-16)
        }

        // 횟수 컨테이너
        contentView.addSubview(countContainer)
        countContainer.addSubview(countLabel)
        countContainer.addSubview(countStepper)

        countContainer.snp.makeConstraints {
            $0.top.equalTo(endSectionLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }

        countLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        countStepper.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        // 날짜 컨테이너
        contentView.addSubview(dateContainer)
        dateContainer.addSubview(endDatePicker)

        dateContainer.snp.makeConstraints {
            $0.top.equalTo(countContainer.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }

        endDatePicker.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        // 버튼
        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        contentView.addSubview(buttonStack)
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(dateContainer.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
            $0.bottom.equalToSuperview().offset(-24)
        }

        // 접근성
        setupAccessibility()
    }

    private func createSectionContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }

    private func setupAccessibility() {
        frequencySegment.accessibilityLabel = "반복 빈도"
        intervalStepper.accessibilityLabel = "반복 간격"
        endConditionSegment.accessibilityLabel = "종료 조건"
        countStepper.accessibilityLabel = "종료 횟수"
        saveButton.accessibilityLabel = "완료"
        saveButton.accessibilityHint = "반복 설정을 저장합니다"
        cancelButton.accessibilityLabel = "취소"
        cancelButton.accessibilityHint = "변경 사항을 취소합니다"
    }

    // MARK: - Restore Initial Info

    private func restoreInitialInfo() {
        guard let info = initialInfo else { return }

        selectedFrequency = info.frequency
        selectedInterval = info.interval

        switch info.frequency {
        case "daily": frequencySegment.selectedSegmentIndex = 0
        case "weekly": frequencySegment.selectedSegmentIndex = 1
        case "monthly": frequencySegment.selectedSegmentIndex = 2
        case "yearly": frequencySegment.selectedSegmentIndex = 3
        default: break
        }

        intervalStepper.value = Double(info.interval)

        if let days = info.daysOfWeek {
            selectedDaysOfWeek = Set(days)
            for button in weekdayButtons {
                updateWeekdayButton(button, selected: selectedDaysOfWeek.contains(button.tag))
            }
        }

        selectedDayOfMonth = info.dayOfMonth

        if let endDateStr = info.endDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: endDateStr) {
                endCondition = .onDate
                endDate = date
                endDatePicker.date = date
                endConditionSegment.selectedSegmentIndex = 2
                dateContainer.isHidden = false
            }
        } else if let count = info.endAfterCount {
            endCondition = .afterCount
            endAfterCount = count
            countStepper.value = Double(count)
            endConditionSegment.selectedSegmentIndex = 1
            countContainer.isHidden = false
        }

        updateIntervalLabel()
        updateWeekdayVisibility()
    }

    // MARK: - Actions

    @objc private func frequencyChanged(_ sender: UISegmentedControl) {
        let frequencies = ["daily", "weekly", "monthly", "yearly"]
        selectedFrequency = frequencies[sender.selectedSegmentIndex]
        updateIntervalLabel()
        updateWeekdayVisibility()
    }

    @objc private func intervalChanged(_ sender: UIStepper) {
        selectedInterval = Int(sender.value)
        updateIntervalLabel()
    }

    @objc private func weekdayTapped(_ sender: UIButton) {
        let day = sender.tag
        if selectedDaysOfWeek.contains(day) {
            selectedDaysOfWeek.remove(day)
            updateWeekdayButton(sender, selected: false)
        } else {
            selectedDaysOfWeek.insert(day)
            updateWeekdayButton(sender, selected: true)
        }
    }

    @objc private func endConditionChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            endCondition = .never
            countContainer.isHidden = true
            dateContainer.isHidden = true
        case 1:
            endCondition = .afterCount
            countContainer.isHidden = false
            dateContainer.isHidden = true
        case 2:
            endCondition = .onDate
            countContainer.isHidden = true
            dateContainer.isHidden = false
        default:
            break
        }
    }

    @objc private func countChanged(_ sender: UIStepper) {
        endAfterCount = Int(sender.value)
        countLabel.text = "\(endAfterCount)회 후 종료"
    }

    @objc private func endDateChanged(_ sender: UIDatePicker) {
        endDate = sender.date
    }

    @objc private func saveTapped() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var endDateStr: String? = nil
        var endCount: Int? = nil

        switch endCondition {
        case .never: break
        case .afterCount: endCount = endAfterCount
        case .onDate: endDateStr = endDate.map { formatter.string(from: $0) }
        }

        let daysOfWeek: [Int]? = (selectedFrequency == "weekly" && !selectedDaysOfWeek.isEmpty) ? Array(selectedDaysOfWeek).sorted() : nil
        let dayOfMonth: Int? = (selectedFrequency == "monthly") ? selectedDayOfMonth : nil

        let info = RecurrenceInfo(
            frequency: selectedFrequency,
            interval: selectedInterval,
            endDate: endDateStr,
            endAfterCount: endCount,
            daysOfWeek: daysOfWeek,
            dayOfMonth: dayOfMonth
        )

        onRecurrenceSelected?(info)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    // MARK: - UI Helpers

    private func updateIntervalLabel() {
        let unit: String
        switch selectedFrequency {
        case "daily": unit = "일"
        case "weekly": unit = "주"
        case "monthly": unit = "개월"
        case "yearly": unit = "년"
        default: unit = ""
        }
        intervalLabel.text = "\(selectedInterval)\(unit)마다"
    }

    private func updateWeekdayVisibility() {
        let shouldShow = selectedFrequency == "weekly"
        UIView.animate(withDuration: 0.25) {
            self.weekdayContainer.alpha = shouldShow ? 1 : 0
            self.weekdayContainer.isHidden = !shouldShow
        }
    }

    private func updateWeekdayButton(_ button: UIButton, selected: Bool) {
        if selected {
            button.backgroundColor = AppColors.textHighlighted
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = AppColors.textFieldBackground
            button.setTitleColor(AppColors.textPrimary, for: .normal)
        }
    }
}
