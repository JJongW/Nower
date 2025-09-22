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
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .left
        label.text = "열심히 테스트 중입니다!! 아직! v0.0.1"
        label.textColor = AppColors.textPrimary
        return label
    }()

    let previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("<", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.tintColor = AppColors.textHighlighted
        return button
    }()

    let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(">", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.tintColor = AppColors.textHighlighted
        return button
    }()

    private let weekdayStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 0
        return stack
    }()

    let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(DateCell.self, forCellWithReuseIdentifier: DateCell.identifier)
        return collectionView
    }()
    
    // MARK: - 기간별 일정 오버레이를 위한 컨테이너
    let periodEventOverlayContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false // 터치 이벤트는 하위 collectionView로 전달
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white

        addSubview(monthLabel)
        addSubview(previousButton)
        addSubview(nextButton)
        addSubview(textLabel)
        addSubview(weekdayStackView)
        addSubview(collectionView)
        addSubview(periodEventOverlayContainer) // 오버레이를 가장 위에 추가

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
            $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(16)
            $0.centerX.equalToSuperview()
        }

        previousButton.snp.makeConstraints {
            $0.centerY.equalTo(monthLabel)
            $0.leading.equalToSuperview().offset(20)
        }

        nextButton.snp.makeConstraints {
            $0.centerY.equalTo(monthLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        textLabel.snp.makeConstraints {
            $0.top.equalTo(monthLabel.snp.bottom).offset(48)
            $0.leading.equalToSuperview().offset(20)
        }

        weekdayStackView.snp.makeConstraints {
            $0.top.equalTo(textLabel.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.height.equalTo(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(weekdayStackView.snp.bottom).offset(36)
            $0.leading.equalToSuperview().offset(8)
            $0.trailing.equalToSuperview().offset(-8)
            $0.bottom.equalToSuperview()
        }
        
        // 오버레이 컨테이너는 collectionView와 동일한 영역을 차지
        periodEventOverlayContainer.snp.makeConstraints {
            $0.edges.equalTo(collectionView)
        }
    }
    
    // MARK: - 기간별 일정 오버레이 관리
    
    /// 기간별 일정 오버레이를 모두 제거합니다.
    func clearPeriodEventOverlays() {
        periodEventOverlayContainer.subviews.forEach { $0.removeFromSuperview() }
    }
    
    /// 기간별 일정 오버레이를 추가합니다.
    /// - Parameters:
    ///   - todo: 기간별 일정 아이템
    ///   - segments: 기간별 일정의 각 세그먼트 정보
    ///   - row: 해당 일정이 표시될 행 (0부터 시작)
    func addPeriodEventOverlay(todo: TodoItem, segments: [PeriodEventSegment], row: Int) {
        let overlayView = PeriodEventOverlayView()
        
        // 오버레이 뷰의 전체 프레임을 모든 세그먼트를 포함하도록 설정
        if !segments.isEmpty {
            let minX = segments.map { $0.frame.minX }.min() ?? 0
            let minY = segments.map { $0.frame.minY }.min() ?? 0
            let maxX = segments.map { $0.frame.maxX }.max() ?? 0
            let maxY = segments.map { $0.frame.maxY }.max() ?? 0
            
            let overlayFrame = CGRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
            )
            
            overlayView.frame = overlayFrame
            print("🖼️ [CalendarView] 오버레이 프레임: \(overlayFrame)")
            
            // 프레임 설정 후 configure 호출
            overlayView.configure(todo: todo, segments: segments, row: row)
            
            periodEventOverlayContainer.addSubview(overlayView)
            print("✅ [CalendarView] 오버레이 추가됨: \(todo.text)")
        }
    }
}
