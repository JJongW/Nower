//
//  CalendarView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit
import SnapKit

final class CalendarView: UIView {

    let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = AppColors.textPrimary
        return label
    }()

    let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium) // 축소 (12 → 11)
        label.textAlignment = .left
        label.text = DailyQuoteManager.getTodayQuote()
        label.textColor = AppColors.textFieldPlaceholder // 덜 강조
        label.numberOfLines = 1 // 한 줄로 제한
        return label
    }()

    let previousButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "ic_left_arrow")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = AppColors.coralred
        return button
    }()

    let nextButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "ic_right_arrow")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = AppColors.coralred
        return button
    }()

    let syncStatusView = SyncStatusBarView()

    private let weekdayStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 0
        return stack
    }()

    let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    /// 하루 밀도 컴팩트 칩을 담는 컨테이너 (헤더, 월 라벨 아래 우측)
    let densityChipContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0 // 셀 간격 제거
        layout.minimumLineSpacing = 0 // 행 간격 제거
        layout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = AppColors.background
        collectionView.register(WeekCell.self, forCellWithReuseIdentifier: WeekCell.identifier)
        collectionView.isScrollEnabled = false // 스크롤 비활성화 (한 화면에 모두 표시)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.clipsToBounds = true // 가장자리 클리핑으로 겹침 방지
        return collectionView
    }()

    /// 하단 인라인 일정 패널을 호스팅하는 컨테이너 (자식 VC의 view를 담음).
    /// 기본 높이 0 = 숨김. 날짜 탭 시 peek 높이로 등장.
    let schedulePanelContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = false
        return view
    }()

    /// 패널 높이 제약 — VC가 drag/스프링으로 갱신. 0이면 숨김.
    var panelHeightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColors.background
        clipsToBounds = true // 부모 뷰도 클리핑 설정으로 겹침 방지

        addSubview(monthLabel)
        addSubview(previousButton)
        addSubview(nextButton)
        addSubview(syncStatusView)
        addSubview(textLabel)
        addSubview(weekdayStackView)
        addSubview(densityChipContainer)
        addSubview(collectionView)
        addSubview(schedulePanelContainer)

        for (index, day) in weekdays.enumerated() {
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)

            if index == 0 {
                label.textColor = AppColors.coralred
            } else if index == 6 {
                label.textColor = AppColors.skyblue
            } else {
                label.textColor = AppColors.textPrimary
            }

            weekdayStackView.addArrangedSubview(label)
        }

        monthLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(8) // 축소 (16 → 8)
            $0.centerX.equalToSuperview()
        }

        // 화면 끝과 monthLabel 중간 지점에 배치하기 위한 가이드 뷰
        let leftGuide = UILayoutGuide()
        let rightGuide = UILayoutGuide()
        addLayoutGuide(leftGuide)
        addLayoutGuide(rightGuide)

        // leftGuide: leading ~ monthLabel.leading 사이 전체
        leftGuide.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalTo(monthLabel.snp.leading)
        }

        // rightGuide: monthLabel.trailing ~ trailing 사이 전체
        rightGuide.snp.makeConstraints {
            $0.leading.equalTo(monthLabel.snp.trailing)
            $0.trailing.equalToSuperview()
        }

        previousButton.snp.makeConstraints {
            $0.centerY.equalTo(monthLabel)
            $0.centerX.equalTo(leftGuide)
            $0.size.equalTo(24)
        }

        nextButton.snp.makeConstraints {
            $0.centerY.equalTo(monthLabel)
            $0.centerX.equalTo(rightGuide)
            $0.size.equalTo(24)
        }

        syncStatusView.snp.makeConstraints {
            $0.centerY.equalTo(monthLabel)
            $0.trailing.equalToSuperview().inset(16)
        }

        textLabel.snp.makeConstraints {
            $0.top.equalTo(monthLabel.snp.bottom).offset(12) // 축소 (48 → 12)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalTo(densityChipContainer.snp.leading).offset(-8)
        }

        // 밀도 컴팩트 칩: 명언 줄 우측. 내부 SwiftUI 콘텐츠가 크기 결정.
        densityChipContainer.snp.makeConstraints {
            $0.centerY.equalTo(textLabel)
            $0.trailing.equalToSuperview().inset(16)
        }
        densityChipContainer.setContentHuggingPriority(.required, for: .horizontal)
        densityChipContainer.setContentCompressionResistancePriority(.required, for: .horizontal)

        weekdayStackView.snp.makeConstraints {
            $0.top.equalTo(textLabel.snp.bottom).offset(16) // 축소 (36 → 16)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.height.equalTo(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(weekdayStackView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(8)
            // 그리드 하단을 패널 상단에 핀: 패널이 올라오면 그리드가 줄어들고(접힘),
            // 동시에 캡슐→점 코스메틱이 진행되어 작아진 영역에 점이 깔끔히 들어감.
            $0.bottom.equalTo(schedulePanelContainer.snp.top)
        }

        schedulePanelContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview() // safeArea 아래까지 확장 (패널 내부에서 safe inset 처리)
            self.panelHeightConstraint = $0.height.equalTo(0).constraint
        }
    }
}
