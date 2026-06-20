//
//  NewEventView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//

import UIKit
import SnapKit
#if canImport(NowerCore)
import NowerCore
#endif

final class NewEventView: UIView {

    // MARK: - Components

    let dateContextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = AppColors.textPrimary
        return label
    }()

    let textFieldBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    let textField: UITextField = {
        let textField = UITextField()
        let examples = ["점심 약속", "팀 미팅", "치과 예약", "운동", "생일 파티"]
        textField.placeholder = examples.randomElement()
        textField.textColor = AppColors.textPrimary
        textField.setPlaceholder(color: AppColors.textFieldPlaceholder)
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.returnKeyType = .done
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
        button.isEnabled = false
        button.alpha = 0.4
        return button
    }()
    
    // 삭제는 위험 동작 — 저장과 동등한 무게를 주지 않는다 (UX 검토 §12).
    // 테두리/박스 제거해 조용한 텍스트로 강등. 확인 다이얼로그는 VC에서 유지.
    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("일정 삭제", for: .normal)
        button.setTitleColor(UIColor.systemRed.withAlphaComponent(0.85), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.backgroundColor = .clear
        return button
    }()

    // 제목 입력 시 노출. 저대비 텍스트라 잘 안 보여 아이콘+강조색으로 발견성↑ (UX 검토 P3).
    let saveTemplateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(" 템플릿으로 저장", for: .normal)
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.setTitleColor(AppColors.textHighlighted, for: .normal)
        button.tintColor = AppColors.textHighlighted
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.isHidden = true
        return button
    }()

    #if canImport(NowerCore)
    let autocompleteView = TemplateAutocompleteView()

    /// 자연어 분석 결과를 적용하는 제안 pill (제목에서 날짜/시간/반복을 감지하면 노출).
    /// 자동 저장하지 않고, 사용자가 탭해야 폼에 반영된다.
    let nlApplyButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = AppColors.textFieldBackground
        b.layer.cornerRadius = 10
        b.isHidden = true
        return b
    }()
    /// pill 내부 — 화살표 아이콘
    private let nlArrowIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "ic_arrow_enter_right")?.withRenderingMode(.alwaysTemplate))
        iv.tintColor = AppColors.textHighlighted
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        return iv
    }()
    /// pill 내부 — 일정 텍스트(길면 가운데를 줄임)
    private let nlDetailLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = AppColors.textHighlighted
        l.lineBreakMode = .byTruncatingMiddle
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // 평소엔 전체 표시(폭 확보), 넘칠 때만 줄어듦 — apply(required)보다 낮아 detail이 먼저 양보
        l.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return l
    }()
    /// pill 내부 — "적용" (절대 잘리지 않음)
    private let nlApplyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = AppColors.textHighlighted
        l.text = "적용"
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()
    private var nlHeightConstraint: Constraint?
    /// 오전/오후 토글 폭 — 숨김 시 0으로 접어 pill이 한 줄을 다 쓰게 한다.
    private var meridiemWidthConstraint: Constraint?
    private var currentDraft: ParsedEventDraft?

    /// 오전/오후가 모호한 시각("3시" 등)을 교정하는 토글. 모호할 때만 노출.
    let meridiemToggle: UISegmentedControl = {
        let c = UISegmentedControl(items: ["오전", "오후"])
        c.selectedSegmentIndex = 1
        c.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 11, weight: .medium)], for: .normal)
        c.isHidden = true
        return c
    }()
    /// 토글로 오전/오후를 뒤집기 위한 기준 12시간제 시(1~11)와 분.
    private var nlBaseHour: Int?
    private var nlMinute: Int = 0
    #endif

    private var autocompleteHeightConstraint: Constraint?

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
        button.setTitleColor(AppColors.textFieldPlaceholder, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()

    private let timeChevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = AppColors.textFieldPlaceholder
        iv.contentMode = .scaleAspectFit
        return iv
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

    private let reminderChevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = AppColors.textFieldPlaceholder
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let reminderIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_alarm")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = AppColors.textFieldPlaceholder
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
        button.setTitleColor(AppColors.textFieldPlaceholder, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()

    // MARK: - 반복 설정 컴포넌트

    let recurrenceSettingContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    private let recurrenceChevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = AppColors.textFieldPlaceholder
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let recurrenceIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.2.squarepath")
        imageView.tintColor = AppColors.textFieldPlaceholder
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let recurrenceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "반복"
        label.textColor = AppColors.textPrimary
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    let recurrenceValueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("안 함", for: .normal)
        button.setTitleColor(AppColors.textFieldPlaceholder, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()

    // MARK: - 반복 프로퍼티

    var selectedRecurrenceInfo: RecurrenceInfo? {
        didSet { updateRecurrenceDisplay() }
    }

    // MARK: - 기존 컴포넌트들

    private(set) var colorOptions: [UIButton] = []
    var selectedColorName: String = "skyblue-4" { // 기본값을 중간 톤으로 설정
        didSet {
            updateColorSelection()
        }
    }
    let colorNames: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]
    private var colorVariationPicker: ColorVariationPickerView?

    /// 저장 버튼 활성 시 표시할 텍스트 (기본: "추가", 편집 시 "수정"으로 변경)
    var saveButtonActiveTitle: String = "추가"
    
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
        didSet {
            updateTimeDisplay()
            updateEndTimeRowVisibility()
        }
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
        textField.delegate = self
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
        sv.alwaysBounceVertical = false
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private let contentView = UIView()

    private let buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.spacing = 10
        stack.alignment = .fill
        return stack
    }()

    private var buttonBottomConstraint: Constraint?

    // MARK: - UI Setup

    private func setupUI() {
        backgroundColor = AppColors.popupBackground

        // 저장/삭제 버튼 컨테이너 (스크롤뷰 밖, 하단 고정)
        addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.addArrangedSubview(deleteButton)

        buttonStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            buttonBottomConstraint = $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-32).constraint
        }

        saveButton.snp.makeConstraints {
            $0.height.equalTo(52)
        }

        deleteButton.snp.makeConstraints {
            $0.height.equalTo(48)
        }

        deleteButton.isHidden = true

        // 스크롤뷰 설정
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(buttonStackView.snp.top).offset(-8)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // 날짜 컨텍스트 라벨
        contentView.addSubview(dateContextLabel)
        dateContextLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(48) // 8pt 그리드 (48 = 6 * 8), grabber 아래 충분한 여백
            $0.leading.equalToSuperview().offset(24)
        }

        // 텍스트 필드
        contentView.addSubview(textFieldBackgroundView)
        contentView.addSubview(textField)

        // design-skills: 8pt 그리드 시스템
        textFieldBackgroundView.snp.makeConstraints {
            $0.top.equalTo(dateContextLabel.snp.bottom).offset(12)
            $0.height.equalTo(56) // 최소 터치 타겟 44pt + 패딩
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        textField.snp.makeConstraints {
            $0.center.equalTo(textFieldBackgroundView)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        // 템플릿 자동완성 드롭다운 (textFieldBackgroundView 바로 아래, 초기 height=0)
        #if canImport(NowerCore)
        contentView.addSubview(autocompleteView)
        autocompleteView.snp.makeConstraints {
            $0.top.equalTo(textFieldBackgroundView.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(20)
            autocompleteHeightConstraint = $0.height.equalTo(0).constraint
        }
        #endif

        // 템플릿 저장 버튼 (textFieldBackgroundView 우측 하단)
        contentView.addSubview(saveTemplateButton)
        saveTemplateButton.snp.makeConstraints {
            #if canImport(NowerCore)
            $0.top.equalTo(autocompleteView.snp.bottom).offset(4)
            #else
            $0.top.equalTo(textFieldBackgroundView.snp.bottom).offset(4)
            #endif
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(20)
        }

        // 자연어 분석 제안 pill (초기 height=0, 감지 시 노출)
        #if canImport(NowerCore)
        contentView.addSubview(nlApplyButton)
        contentView.addSubview(meridiemToggle)

        // 토글: 우측 고정. 숨김 시 width=0으로 접어 pill에 공간을 넘긴다.
        meridiemToggle.snp.makeConstraints {
            $0.centerY.equalTo(nlApplyButton)
            $0.trailing.equalToSuperview().inset(20)
            meridiemWidthConstraint = $0.width.equalTo(0).constraint
        }
        meridiemWidthConstraint?.deactivate() // 기본: 토글 표시(자연 폭)
        meridiemToggle.setContentHuggingPriority(.required, for: .horizontal)
        // 숨김 시 width=0 제약이 이기도록 압축저항을 낮춘다.
        meridiemToggle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // pill: 내부 서브뷰 체인이 폭을 결정 → 배경이 글자에 딱 맞음.
        // 길면 토글 leading까지만 늘고(≤), 그 안에서 일정 텍스트만 가운데를 줄인다.
        nlApplyButton.snp.makeConstraints {
            $0.top.equalTo(saveTemplateButton.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualTo(meridiemToggle.snp.leading).offset(-8)
            nlHeightConstraint = $0.height.equalTo(0).constraint
        }
        nlApplyButton.addSubview(nlArrowIcon)
        nlApplyButton.addSubview(nlDetailLabel)
        nlApplyButton.addSubview(nlApplyLabel)
        nlArrowIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(15)
        }
        nlDetailLabel.snp.makeConstraints {
            $0.leading.equalTo(nlArrowIcon.snp.trailing).offset(6)
            $0.centerY.equalToSuperview()
        }
        nlApplyLabel.snp.makeConstraints {
            $0.leading.equalTo(nlDetailLabel.snp.trailing).offset(5)
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
        nlApplyButton.addTarget(self, action: #selector(applyNaturalLanguage), for: .touchUpInside)
        // 숨김 시 width=0 제약이 이기도록 압축저항을 낮춘다(요소 자체 폭 < 0 제약).
        meridiemToggle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        meridiemToggle.addTarget(self, action: #selector(meridiemChanged), for: .valueChanged)
        #endif

        // 기간 모드 스위치
        contentView.addSubview(periodModeContainer)
        periodModeContainer.addSubview(periodModeLabel)
        periodModeContainer.addSubview(periodModeSwitch)

        periodModeContainer.snp.makeConstraints {
            #if canImport(NowerCore)
            $0.top.equalTo(nlApplyButton.snp.bottom).offset(8)
            #else
            $0.top.equalTo(saveTemplateButton.snp.bottom).offset(8) // 8pt 그리드
            #endif
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
        timeSettingContainer.addSubview(timeChevron)

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

        timeChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8)
            $0.height.equalTo(13)
        }

        timeValueButton.snp.makeConstraints {
            $0.trailing.equalTo(timeChevron.snp.leading).offset(-8)
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
        reminderSettingContainer.addSubview(reminderChevron)
        reminderSettingContainer.addSubview(reminderValueButton)

        reminderSettingContainer.snp.makeConstraints {
            $0.top.equalTo(endTimeSettingContainer.snp.bottom).offset(16)
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

        reminderChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8)
            $0.height.equalTo(13)
        }

        reminderValueButton.snp.makeConstraints {
            $0.trailing.equalTo(reminderChevron.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }

        // 시간 미설정 시 알림 행 비활성화
        updateReminderEnabled()

        // 반복 설정 행
        contentView.addSubview(recurrenceSettingContainer)
        recurrenceSettingContainer.addSubview(recurrenceIconView)
        recurrenceSettingContainer.addSubview(recurrenceTitleLabel)
        recurrenceSettingContainer.addSubview(recurrenceChevron)
        recurrenceSettingContainer.addSubview(recurrenceValueButton)

        recurrenceSettingContainer.snp.makeConstraints {
            $0.top.equalTo(reminderSettingContainer.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }

        recurrenceIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        recurrenceTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(recurrenceIconView.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        recurrenceChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8)
            $0.height.equalTo(13)
        }

        recurrenceValueButton.snp.makeConstraints {
            $0.trailing.equalTo(recurrenceChevron.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }

        // 색상 선택
        contentView.addSubview(colorStackView)

        colorStackView.snp.makeConstraints {
            $0.top.equalTo(recurrenceSettingContainer.snp.bottom).offset(24) // 8pt 그리드 (24 = 3 * 8)
            $0.leading.trailing.equalToSuperview().inset(32)
            $0.height.equalTo(40)
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

        // 스크롤 콘텐츠 하단 여백
        colorStackView.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-24)
        }

        // 스위치 액션 설정
        periodModeSwitch.addTarget(self, action: #selector(periodModeSwitchChanged(_:)), for: .valueChanged)
        startDateButton.addTarget(self, action: #selector(startDateButtonTapped), for: .touchUpInside)
        endDateButton.addTarget(self, action: #selector(endDateButtonTapped), for: .touchUpInside)

        // 하루 종일 스위치 액션
        // 시간/알림/반복 버튼 액션
        timeValueButton.addTarget(self, action: #selector(timeValueButtonTapped), for: .touchUpInside)
        endTimeValueButton.addTarget(self, action: #selector(endTimeValueButtonTapped), for: .touchUpInside)
        reminderValueButton.addTarget(self, action: #selector(reminderValueButtonTapped), for: .touchUpInside)
        recurrenceValueButton.addTarget(self, action: #selector(recurrenceValueButtonTapped), for: .touchUpInside)

        // 행 전체 탭 제스처
        let timeTap = UITapGestureRecognizer(target: self, action: #selector(timeRowTapped))
        timeSettingContainer.addGestureRecognizer(timeTap)
        let reminderTap = UITapGestureRecognizer(target: self, action: #selector(reminderRowTapped))
        reminderSettingContainer.addGestureRecognizer(reminderTap)
        let recurrenceTap = UITapGestureRecognizer(target: self, action: #selector(recurrenceRowTapped))
        recurrenceSettingContainer.addGestureRecognizer(recurrenceTap)

        // 버튼 눌림 효과 적용
        saveButton.addPressAnimation()
        deleteButton.addPressAnimation()
        startDateButton.addPressAnimation()
        endDateButton.addPressAnimation()
        timeValueButton.addPressAnimation()
        endTimeValueButton.addPressAnimation()
        reminderValueButton.addPressAnimation()
        recurrenceValueButton.addPressAnimation()
        saveTemplateButton.addPressAnimation()

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
            button.accessibilityHint = "탭하여 선택"
        }

        // 시간/알림 버튼
        timeValueButton.accessibilityLabel = "시간 설정"
        timeValueButton.accessibilityHint = "탭하여 일정 시간을 설정하세요"
        endTimeValueButton.accessibilityLabel = "종료 시간 설정"
        endTimeValueButton.accessibilityHint = "탭하여 종료 시간을 설정하세요"
        reminderValueButton.accessibilityLabel = "알림 설정"
        reminderValueButton.accessibilityHint = "탭하여 알림을 설정하세요"

        // 반복 버튼
        recurrenceValueButton.accessibilityLabel = "반복 설정"
        recurrenceValueButton.accessibilityHint = "탭하여 반복 일정을 설정하세요"

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
        let bottomInset = safeAreaInsets.bottom
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        // 버튼을 키보드 위로 이동 (scrollView는 버튼에 연결되어 자동 축소)
        buttonBottomConstraint?.update(offset: -(keyboardHeight - bottomInset + 8))

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        buttonBottomConstraint?.update(offset: -32)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.layoutIfNeeded()
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
        updateRecurrenceEnabled()
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
            // 펼치기 (기간 날짜 선택)
            dateSelectionContainer.isHidden = false
            dateSelectionContainer.alpha = 0
            dateContainerHeightConstraint?.constant = 100
            dateContainerTopConstraint?.constant = 12

            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut]
            ) {
                self.dateSelectionContainer.alpha = 1
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
                self.layoutIfNeeded()
            } completion: { _ in
                self.dateSelectionContainer.isHidden = true
            }
        }
        // 종료 시간 행은 기간 모드뿐 아니라 "시작 시간이 있는 단일 일정"에도 노출한다.
        updateEndTimeRowVisibility()
    }

    /// 종료 시간 행 노출 갱신.
    /// - 기간 모드: 항상 노출(시작·종료 구간 필요)
    /// - 단일 일정: 시작 시각이 있으면 노출(같은 날 종료 시각 직접 편집)
    private func updateEndTimeRowVisibility() {
        let shouldShow = isPeriodMode || (selectedScheduledTime != nil)

        // 단일 일정에서 시작 시각을 지우면 종료 시각도 의미가 없으므로 함께 비운다.
        if !shouldShow && selectedEndScheduledTime != nil {
            selectedEndScheduledTime = nil
        }

        if shouldShow { endTimeSettingContainer.isHidden = false }
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut]
        ) {
            self.endTimeSettingContainer.alpha = shouldShow ? 1 : 0
            self.endTimeContainerHeightConstraint?.constant = shouldShow ? 52 : 0
            self.endTimeContainerTopConstraint?.constant = shouldShow ? 8 : 0
            self.timeTitleLabel.text = shouldShow ? "시작 시간" : "시간"
            self.layoutIfNeeded()
        } completion: { _ in
            if !shouldShow { self.endTimeSettingContainer.isHidden = true }
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
    
    // MARK: - Row Tap Actions

    @objc private func timeRowTapped() {
        timeValueButtonTapped()
    }

    @objc private func reminderRowTapped() {
        reminderValueButtonTapped()
    }

    @objc private func recurrenceRowTapped() {
        recurrenceValueButtonTapped()
    }

    // MARK: - 시간/알림 Actions

    /// 타임피커에 보여줄 맥락 한 줄 (예: "코딩테스트 · 6월 7일")
    private func timePickerContextText() -> String? {
        let title = textField.text?.trimmingCharacters(in: .whitespaces)
        let date = initialSelectedDate ?? selectedStartDate
        let dateStr: String? = date.map {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = "M월 d일"
            return f.string(from: $0)
        }
        let parts = [title, dateStr].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    @objc private func timeValueButtonTapped() {
        endEditing(true)
        guard let parentView = findViewController()?.view else { return }
        let picker = TimePickerView(currentTime: selectedScheduledTime, contextText: timePickerContextText())
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
        endEditing(true)
        guard let parentView = findViewController()?.view else { return }
        // 종료 시간 피커: 빈 값이면 휠을 바로 노출(시작 시각으로 시드)하고, 토글은 "종료 시간 없음".
        let picker = TimePickerView(
            currentTime: selectedEndScheduledTime,
            contextText: timePickerContextText(),
            allDayTitle: "종료 시간 없음",
            allDayWhenEmpty: false,
            seedTime: selectedScheduledTime
        )
        picker.onTimeSelected = { [weak self] time in
            self?.selectedEndScheduledTime = time
        }
        parentView.addSubview(picker)
        picker.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @objc private func reminderValueButtonTapped() {
        endEditing(true)
        guard selectedScheduledTime != nil else {
            findViewController()?.showToast(message: "시간을 설정하면 알림을 추가할 수 있어요")
            return
        }
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
            timeValueButton.setTitleColor(AppColors.textHighlighted, for: .normal)
        } else {
            timeValueButton.setTitle("하루 종일", for: .normal)
            timeValueButton.setTitleColor(AppColors.textFieldPlaceholder, for: .normal)
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
            endTimeValueButton.setTitle(isPeriodMode ? "하루 종일" : "미설정", for: .normal)
        }
    }

    private func updateReminderDisplay() {
        guard let minutes = selectedReminderMinutesBefore else {
            reminderValueButton.setTitle("없음", for: .normal)
            reminderValueButton.setTitleColor(AppColors.textFieldPlaceholder, for: .normal)
            return
        }
        reminderValueButton.setTitleColor(AppColors.textHighlighted, for: .normal)
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

    // MARK: - 반복 Actions & Display

    @objc private func recurrenceValueButtonTapped() {
        endEditing(true)
        // 기간 모드와 상호 배타
        if isPeriodMode {
            // 기간 모드에서는 반복 비활성화 → 안내
            findViewController()?.showToast(message: "기간별 일정은 반복 설정을 함께 사용할 수 없어요")
            return
        }

        guard let parentView = findViewController()?.view,
              let parentVC = findViewController() else { return }

        let picker = RecurrencePickerView(currentInfo: selectedRecurrenceInfo)
        picker.onRecurrenceSelected = { [weak self] info in
            self?.selectedRecurrenceInfo = info
            self?.updateRecurrencePeriodExclusivity()
        }
        picker.onCustomRequested = { [weak self] in
            guard let self = self else { return }
            let customVC = CustomRecurrenceViewController()
            customVC.initialInfo = self.selectedRecurrenceInfo
            customVC.anchorDate = self.initialSelectedDate ?? self.selectedStartDate ?? Date()
            customVC.onRecurrenceSelected = { [weak self] info in
                self?.selectedRecurrenceInfo = info
                self?.updateRecurrencePeriodExclusivity()
            }
            customVC.modalPresentationStyle = .pageSheet
            if let sheet = customVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
            parentVC.present(customVC, animated: true)
        }
        parentView.addSubview(picker)
        picker.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func updateRecurrenceDisplay() {
        if let info = selectedRecurrenceInfo {
            recurrenceValueButton.setTitle(info.displayString, for: .normal)
            recurrenceValueButton.setTitleColor(AppColors.textHighlighted, for: .normal)
        } else {
            recurrenceValueButton.setTitle("안 함", for: .normal)
            recurrenceValueButton.setTitleColor(AppColors.textFieldPlaceholder, for: .normal)
        }
    }

    /// 반복과 기간 모드의 상호 배타 처리
    private func updateRecurrencePeriodExclusivity() {
        if selectedRecurrenceInfo != nil {
            // 반복이 설정되면 기간 모드 비활성화
            periodModeSwitch.isEnabled = false
            periodModeContainer.alpha = 0.4
        } else {
            periodModeSwitch.isEnabled = true
            periodModeContainer.alpha = 1.0
        }
    }

    /// 기간 모드에 따른 반복 비활성화 업데이트
    func updateRecurrenceEnabled() {
        if isPeriodMode {
            recurrenceSettingContainer.alpha = 0.4
            recurrenceValueButton.isEnabled = false
            // 반복이 설정되어 있었으면 해제
            if selectedRecurrenceInfo != nil {
                selectedRecurrenceInfo = nil
            }
            // 비활성 사유를 인라인으로 설명 (UX 검토 §8)
            recurrenceValueButton.setTitle("기간 일정은 반복 미지원", for: .normal)
            recurrenceValueButton.setTitleColor(AppColors.textFieldPlaceholder, for: .normal)
        } else {
            recurrenceSettingContainer.alpha = 1.0
            recurrenceValueButton.isEnabled = true
            updateRecurrenceDisplay() // 정상 반복 표시 복원
        }
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
    
    private let colorCheckmarkTag = 9999

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
                    let bgColor = AppColors.color(for: "\(baseName)-\(tone)")
                    button.backgroundColor = bgColor

                    // 체크마크 추가
                    if button.viewWithTag(self.colorCheckmarkTag) == nil {
                        let checkmark = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)))
                        checkmark.tag = self.colorCheckmarkTag
                        checkmark.tintColor = AppColors.contrastingTextColor(for: bgColor)
                        checkmark.contentMode = .scaleAspectFit
                        button.addSubview(checkmark)
                        checkmark.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate([
                            checkmark.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                            checkmark.centerYAnchor.constraint(equalTo: button.centerYAnchor)
                        ])
                    }

                    // 선택 시 살짝 확대
                    button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                } else {
                    button.layer.borderWidth = 0
                    // 선택되지 않은 색상은 중간 톤(4)으로 표시
                    button.backgroundColor = AppColors.color(for: "\(baseName)-4")
                    button.transform = .identity

                    // 체크마크 제거
                    button.viewWithTag(self.colorCheckmarkTag)?.removeFromSuperview()
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
            // 단일 일정도 시작 시각이 있으면 종료 시간 행을 유지한다(편집 진입 등).
            let showEnd = selectedScheduledTime != nil
            endTimeSettingContainer.isHidden = !showEnd
            endTimeSettingContainer.alpha = showEnd ? 1 : 0
            endTimeContainerHeightConstraint?.constant = showEnd ? 52 : 0
            endTimeContainerTopConstraint?.constant = showEnd ? 8 : 0
            timeTitleLabel.text = showEnd ? "시작 시간" : "시간"
        }
        periodModeSwitch.isOn = enabled
        isPeriodMode = enabled
        isSettingPeriodMode = false
        updateDateButtonTitles()
        layoutIfNeeded()
    }

    /// 선택된 날짜 설정 (새 일정 추가 시 외부에서 호출)
    func setInitialSelectedDate(_ date: Date) {
        setDateContext(date, actionText: "에 추가")
    }

    func setDateContext(_ date: Date, actionText: String) {
        initialSelectedDate = date
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        let calendarIcon = UIImage(systemName: "calendar")
        let attachment = NSTextAttachment()
        attachment.image = calendarIcon?.withTintColor(AppColors.textFieldPlaceholder)
        let iconSize: CGFloat = 14
        attachment.bounds = CGRect(x: 0, y: -2, width: iconSize, height: iconSize)
        let attrStr = NSMutableAttributedString(attachment: attachment)
        attrStr.append(NSAttributedString(
            string: " \(formatter.string(from: date))\(actionText)",
            attributes: [
                .font: dateContextLabel.font as Any,
                .foregroundColor: dateContextLabel.textColor as Any
            ]
        ))
        dateContextLabel.attributedText = attrStr
    }

    // MARK: - Save Button State

    @objc private func textFieldDidChange() {
        updateSaveButtonState()
        #if canImport(NowerCore)
        updateNaturalLanguageSuggestion()
        #endif
    }

    #if canImport(NowerCore)
    /// 제목 입력을 자연어로 분석해 적용 제안 pill을 갱신한다. (자동 적용하지 않음)
    private func updateNaturalLanguageSuggestion() {
        let text = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else { hideNLSuggestion(); return }

        let draft = EventDraftParser.parse(text, referenceDate: initialSelectedDate ?? Date())
        currentDraft = draft

        // 시간 또는 반복이 감지된 경우에만 제안 (날짜는 진입점 날짜를 따름)
        guard draft.startTime != nil || draft.recurrenceRule != nil else {
            hideNLSuggestion()
            return
        }

        // 오전/오후 모호 시각이면 토글 노출 + 현재 추정값으로 기준 시/분 저장
        if let s = draft.startTime, draft.startMeridiemAmbiguous {
            nlBaseHour = s.hour > 11 ? s.hour - 12 : s.hour   // 1~11
            nlMinute = s.minute
            meridiemToggle.selectedSegmentIndex = s.hour >= 12 ? 1 : 0
            setMeridiemToggle(visible: true)
        } else {
            nlBaseHour = nil
            setMeridiemToggle(visible: false)
        }

        refreshNLPill()
    }

    /// currentDraft 기준으로 pill 제목/노출을 갱신한다 (재파싱 없이 토글 갱신에도 사용).
    private func refreshNLPill() {
        guard let draft = currentDraft else { return }
        var parts: [String] = []
        if let s = draft.startTime {
            parts.append(draft.endTime != nil ? "\(s.hhmm)~\(draft.endTime!.hhmm)" : s.hhmm)
        }
        if let r = draft.recurrenceRule {
            parts.append(RecurrenceInfo.from(r).displayString)
        }
        if !draft.title.isEmpty {
            parts.append("“\(draft.title)”")
        }
        nlDetailLabel.text = parts.joined(separator: " · ")
        nlApplyButton.isHidden = false
        nlHeightConstraint?.update(offset: 34)
        UIView.animate(withDuration: 0.15) { self.layoutIfNeeded() }
    }

    /// 오전/오후 토글 변경 → 기준 시각을 뒤집어 currentDraft·pill 갱신.
    @objc private func meridiemChanged() {
        guard let base = nlBaseHour else { return }
        let hour = meridiemToggle.selectedSegmentIndex == 1 ? base + 12 : base
        currentDraft?.startTime = ParsedTime(hour: hour % 24, minute: nlMinute)
        refreshNLPill()
    }

    /// 오전/오후 토글 노출 + 폭 제약 동기화(숨김 시 0으로 접어 pill에 공간 반환).
    private func setMeridiemToggle(visible: Bool) {
        meridiemToggle.isHidden = !visible
        if visible { meridiemWidthConstraint?.deactivate() }
        else { meridiemWidthConstraint?.activate() }
    }

    private func hideNLSuggestion() {
        setMeridiemToggle(visible: false)
        nlBaseHour = nil
        guard !nlApplyButton.isHidden else { return }
        nlApplyButton.isHidden = true
        nlHeightConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.15) { self.layoutIfNeeded() }
    }

    /// 제안 pill 탭 → 분석 결과를 폼에 반영 (저장은 여전히 사용자가 추가 버튼으로)
    @objc private func applyNaturalLanguage() {
        guard let d = currentDraft else { return }
        if let s = d.startTime { selectedScheduledTime = s.hhmm }
        // 시간 범위("11:00~18:00")는 같은 날 단일 일정에도 종료 시각을 적용한다.
        // 종료 시각까지 기록해야 빈도/밀도 측정이 실제 점유 시간을 반영한다.
        if let e = d.endTime { selectedEndScheduledTime = e.hhmm }
        if let r = d.recurrenceRule { selectedRecurrenceInfo = RecurrenceInfo.from(r) }
        if !d.title.isEmpty { textField.text = d.title }
        hideNLSuggestion()
        updateSaveButtonState()
    }
    #endif

    func updateSaveButtonState() {
        let hasText = !(textField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        saveButton.isEnabled = hasText
        saveButton.setTitle(hasText ? saveButtonActiveTitle : "제목을 입력하세요", for: .normal)
        saveTemplateButton.isHidden = !hasText
        UIView.animate(withDuration: 0.2) {
            self.saveButton.alpha = hasText ? 1.0 : 0.4
        }
    }

    #if canImport(NowerCore)
    /// 자동완성 드롭다운 업데이트
    func updateAutocomplete(suggestions: [EventTemplate]) {
        autocompleteView.suggestions = suggestions
        let newHeight = suggestions.isEmpty ? 0 : CGFloat(min(suggestions.count, 5)) * TemplateAutocompleteView.rowHeight
        autocompleteHeightConstraint?.update(offset: newHeight)
        UIView.animate(withDuration: 0.15) {
            self.layoutIfNeeded()
        }
    }
    #endif

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

// MARK: - UITextFieldDelegate
extension NewEventView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
