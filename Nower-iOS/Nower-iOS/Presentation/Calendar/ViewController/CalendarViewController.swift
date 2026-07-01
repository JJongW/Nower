//
//  CalendarViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.

import UIKit
import SwiftUI
import SnapKit
import WidgetKit
#if canImport(NowerCore)
import NowerCore
#endif

final class CalendarViewController: UIViewController {

    var coordinator: AppCoordinator?
    private let calendarView = CalendarView()
    /// 하단 인라인 일정 패널 (모달 시트 대체, 2-depth)
    private let schedulePanelVC = SchedulePanelViewController()
    /// 접힘 진행도(0 = 풀 캘린더 + 패널 peek, 1 = 숫자 그리드 + 패널 확장)
    private var collapseProgress: CGFloat = 0
    /// 패널 노출 여부 (런치 시 false = 숨김)
    private var isPanelVisible = false
    #if canImport(NowerCore)
    /// 헤더 밀도 칩 호스팅 컨트롤러
    private var densityChipHostingController: UIHostingController<DensityChipView>?
    /// 현재 월 날짜키 → 밴드 색 hex (히트맵 틴트용)
    private var densityBandHexByDate: [String: String] = [:]
    #endif
    private var currentDate = Date()
    private var weeks: [[WeekDayInfo]] = [] // 주 단위로 그룹화된 날짜들
    /// 다음 일정 경계(시작/끝)에 Live Activity·위젯을 재동기화하기 위한 타이머
    private var boundaryTimer: Timer?

    private var selectedIndexPath: IndexPath?
    private var selectedDate: Date?
    private var isNextMonth = false

    private let viewModel: CalendarViewModel
    private let holidayUseCase: HolidayUseCase
    private var syncStatusViewModel: SyncStatusViewModel?

    // MARK: - Interactive Swipe Properties
    private var panStartLocation: CGPoint = .zero
    private var snapshotView: UIView?
    private var nextMonthSnapshot: UIView?
    private var isTransitioning = false
    private let swipeThreshold: CGFloat = 0.7 // 화면 너비의 70% 이상 스와이프해야 전환

    init(viewModel: CalendarViewModel, holidayUseCase: HolidayUseCase) {
        self.viewModel = viewModel
        self.holidayUseCase = holidayUseCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 날짜가 바뀌었을 수 있으므로 일일 명언 갱신
        calendarView.textLabel.text = DailyQuoteManager.getTodayQuote()
    }

    override func loadView() {
        self.view = calendarView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSchedulePanel()
        setupDensityCard()
        generateCalendar()
        setupSwipeGesture()

        holidayUseCase.preloadAdjacentMonths(baseDate: currentDate, completion: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(icloudDidUpdate),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(forceSync),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        // CloudSyncManager의 알림을 수신하도록 변경
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(todosUpdated),
            name: Notification.Name("CloudSyncManager.todosDidUpdate"),
            object: nil
        )
        // 외부 캘린더(Apple 등) 일정이 갱신되면 달력을 다시 그린다.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(externalTodosUpdated),
            name: ExternalCalendarManager.externalTodosDidChangeNotification,
            object: nil
        )

        calendarView.previousButton.addTarget(self, action: #selector(didTapPreviousMonth), for: .touchUpInside)
        calendarView.nextButton.addTarget(self, action: #selector(didTapNextMonth), for: .touchUpInside)
        calendarView.settingsButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)

        setupSyncStatus()

        viewModel.onSuggestDepartureSetup = { [weak self] kind in
            self?.presentDepartureSetupSuggestion(for: kind)
        }

        viewModel.onAskBufferSeed = { [weak self] in
            self?.presentBufferSeedPrompt()
        }
    }

    @objc private func didTapSettings() {
        coordinator?.presentDepartureSettings()
    }

    /// 집/회사 위치가 비어 있는데 관련 일정을 만들면 1회만 위치 설정을 권유합니다. (US-B2)
    private func presentDepartureSetupSuggestion(for kind: PlaceKind) {
        let place = kind.fixedName ?? "장소"
        let alert = UIAlertController(
            title: "출발 시각 알려드릴까요?",
            message: "\(place) 위치를 넣어두면 늦지 않게 출발할 시각을 미리 알려드려요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "위치 넣기", style: .default) { [weak self] _ in
            self?.coordinator?.presentDepartureSettings()
        })
        alert.addAction(UIAlertAction(title: "괜찮아요", style: .cancel))
        present(alert, animated: true)
    }

    /// 첫 출발 알림이 잡혔을 때 준비 시간을 1회 물어, 전역 준비 버퍼에 반영합니다. (US-E1)
    private func presentBufferSeedPrompt() {
        let alert = UIAlertController(
            title: "준비 시간 알려주세요",
            message: "약속까지 보통 준비하는 데 얼마나 걸려요? (분)",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.keyboardType = .numberPad
            tf.placeholder = "예: 30"
        }
        alert.addAction(UIAlertAction(title: "저장", style: .default) { [weak alert] _ in
            let raw = alert?.textFields?.first?.text ?? ""
            guard let minutes = Int(raw.trimmingCharacters(in: .whitespaces)), minutes >= 0 else { return }
            SavedPlacesManager.shared.setDefaultBuffer(minutes: minutes)
        })
        alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Sync Status

    private func setupSyncStatus() {
        let observer = DependencyContainer.shared.syncStateObserver
        observer.startObserving()

        let vm = SyncStatusViewModel(syncStateObserver: observer)
        self.syncStatusViewModel = vm

        vm.onStateChange = { [weak self] vm in
            guard let self = self else { return }
            self.calendarView.syncStatusView.update(
                iconName: vm.iconName,
                color: vm.iconColor,
                animate: vm.isAnimating,
                accessibilityLabel: vm.accessibilityLabel
            )
            // Task #1: Hide in idle/synced states
            self.calendarView.syncStatusView.setVisible(vm.isVisible, animated: true)
            // Task #5: Update conflict badge
            self.calendarView.syncStatusView.updateBadge(count: vm.conflictCount)
        }

        calendarView.syncStatusView.iconButton.addTarget(self, action: #selector(didTapSyncStatus), for: .touchUpInside)
    }

    @objc private func didTapSyncStatus() {
        guard let vm = syncStatusViewModel else { return }

        if vm.shouldShowAlert {
            // Task #6: Improved error message
            let alert = UIAlertController(
                title: "동기화 문제",
                message: "일정 데이터를 iCloud와 동기화하지 못했습니다. 네트워크 연결을 확인하고 다시 시도해 주세요.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "다시 시도", style: .default) { _ in
                vm.retrySync()
            })
            alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
            present(alert, animated: true)
        } else if vm.shouldShowConflicts {
            let conflictVC = ConflictResolutionViewController(viewModel: vm)
            if let sheet = conflictVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
            present(conflictVC, animated: true)
        } else if let text = vm.lastSyncedText {
            // Task #2: Show last synced timestamp
            showSyncToast(text)
        }
    }

    private func showSyncToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.font = .systemFont(ofSize: 12, weight: .medium)
        toast.textColor = AppColors.textPrimary
        toast.backgroundColor = AppColors.popupBackground
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.layer.masksToBounds = true
        toast.alpha = 0
        toast.sizeToFit()
        toast.frame.size = CGSize(width: toast.frame.width + 24, height: 32)
        toast.center = CGPoint(x: view.center.x, y: view.safeAreaInsets.top + 60)
        view.addSubview(toast)

        UIView.animate(withDuration: 0.3) { toast.alpha = 1 }
        UIView.animate(withDuration: 0.3, delay: 2.0, options: []) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }

    private func setupCollectionView() {
        calendarView.collectionView.dataSource = self
        calendarView.collectionView.delegate = self
    }

    private var horizontalPan: UIPanGestureRecognizer?
    private var verticalPan: UIPanGestureRecognizer?
    private var calendarDragStartProgress: CGFloat = 0
    private var didSummonThisDrag = false

    private func setupSwipeGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        calendarView.collectionView.addGestureRecognizer(panGesture)
        horizontalPan = panGesture

        // 세로 pan: 위로 슬라이드 → 패널 소환/확장, 아래로 → peek/숨김
        let vPan = UIPanGestureRecognizer(target: self, action: #selector(handleCalendarVerticalPan(_:)))
        vPan.delegate = self
        calendarView.collectionView.addGestureRecognizer(vPan)
        verticalPan = vPan
    }

    @objc private func handleCalendarVerticalPan(_ gesture: UIPanGestureRecognizer) {
        let ty = gesture.translation(in: calendarView).y
        let span = max(1, schedulePanelVC.listHeight)

        switch gesture.state {
        case .began:
            progressLink?.invalidate(); progressLink = nil // 드래그가 애니메이션 인수
            calendarDragStartProgress = collapseProgress
            didSummonThisDrag = false
        case .changed:
            if !isPanelVisible {
                // 위로 슬라이드하면 패널 소환 (선택 날짜 없으면 오늘)
                if ty < -8 && !didSummonThisDrag {
                    didSummonThisDrag = true
                    showSchedulePanel(for: selectedDate ?? Date())
                }
                return
            }
            if didSummonThisDrag { return } // 소환 애니메이션 중에는 추적 생략
            let candidate = calendarDragStartProgress + (-ty / span)
            applyCollapseProgress(candidate)
        case .ended, .cancelled:
            guard isPanelVisible, !didSummonThisDrag else { return }
            let vy = gesture.velocity(in: calendarView).y
            let target: CGFloat = abs(vy) > 800 ? (vy < 0 ? 1 : 0) : (collapseProgress > 0.5 ? 1 : 0)
            settlePanel(to: target)
        default:
            break
        }
    }

    // MARK: - Schedule Panel (인라인 하단 패널)

    private func setupSchedulePanel() {
        schedulePanelVC.delegate = self
        addChild(schedulePanelVC)
        calendarView.schedulePanelContainer.addSubview(schedulePanelVC.view)
        schedulePanelVC.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        schedulePanelVC.didMove(toParent: self)
        calendarView.schedulePanelContainer.isHidden = true
    }

    private var lastLayoutHeight: CGFloat = 0

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let h = calendarView.bounds.height
        // 실제 사이즈가 바뀐 경우(회전 등)에만 높이 재계산 — 진행 중 애니메이션과 싸우지 않도록.
        guard h != lastLayoutHeight else { return }
        lastLayoutHeight = h
        updatePanelHeights()
        if isPanelVisible {
            calendarView.panelHeightConstraint?.update(offset: panelHeight(for: collapseProgress))
        }
    }

    /// 화면 크기 기준 리스트(p=1) 높이 산출 후 패널 VC에 주입.
    private func updatePanelHeights() {
        let h = calendarView.bounds.height
        guard h > 0 else { return }
        // p=1에서 화면 하단 약 52%를 리스트가 차지 → 상단 48%는 점 그리드.
        schedulePanelVC.listHeight = (h * 0.52).rounded()
    }

    /// 패널 높이: p=0이면 0(숨김), p=1이면 listHeight. 그리드는 패널 상단에 핀되어
    /// 패널이 올라온 만큼 줄어들고, 코스메틱(캡슐→점)이 함께 진행된다.
    private func panelHeight(for progress: CGFloat) -> CGFloat {
        return schedulePanelVC.listHeight * max(0, min(1, progress))
    }

    /// 진행도 적용: 패널 높이 + 그리드 재분배(전체 압축/스트레치) + 코스메틱(캡슐↔점/숫자).
    private func applyCollapseProgress(_ progress: CGFloat) {
        let p = max(0, min(1, progress))
        collapseProgress = p
        calendarView.panelHeightConstraint?.update(offset: panelHeight(for: p))
        calendarView.collectionView.visibleCells
            .compactMap { $0 as? WeekCell }
            .forEach { $0.collapseProgress = p }
        // 그리드 영역이 줄어든 만큼 행 높이를 재분배 → 달력 전체가 같이 압축되어 올라오고,
        // 되돌릴 때 다시 스트레치된다. (높이만 바뀌면 flow layout이 재질의를 안 하므로 강제 무효화)
        calendarView.collectionView.collectionViewLayout.invalidateLayout()
        calendarView.layoutIfNeeded()
        schedulePanelVC.syncProgress(p)
    }

    // MARK: - Progress 애니메이션 (매 프레임 그리드+패널 동기화)

    private var progressLink: CADisplayLink?
    private var animFrom: CGFloat = 0
    private var animTo: CGFloat = 0
    private var animStart: CFTimeInterval = 0
    private let animDuration: CFTimeInterval = 0.26

    /// CADisplayLink로 progress를 보간하며 매 프레임 applyCollapseProgress 호출 →
    /// 패널 슬라이드와 캘린더 압축/스트레치가 완전히 같이 움직인다.
    private func animateProgress(to target: CGFloat) {
        progressLink?.invalidate()
        animFrom = collapseProgress
        animTo = max(0, min(1, target))
        animStart = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(stepProgress(_:)))
        link.add(to: .main, forMode: .common)
        progressLink = link
    }

    @objc private func stepProgress(_ link: CADisplayLink) {
        let raw = (CACurrentMediaTime() - animStart) / animDuration
        let t = max(0, min(1, raw))
        let eased = 1 - pow(1 - t, 3) // easeOutCubic
        applyCollapseProgress(animFrom + (animTo - animFrom) * CGFloat(eased))
        if t >= 1 {
            link.invalidate()
            progressLink = nil
            if animTo <= 0 {
                isPanelVisible = false
                calendarView.schedulePanelContainer.isHidden = true
            }
        }
    }

    /// 날짜 탭 시 리스트를 끝까지 올리고(p=1) 캘린더를 점 그리드로 접는다.
    private func showSchedulePanel(for date: Date) {
        updatePanelHeights()
        schedulePanelVC.update(date: date, viewModel: viewModel)

        if !isPanelVisible {
            isPanelVisible = true
            calendarView.schedulePanelContainer.isHidden = false
            // 시작 상태: 패널 높이 0 / 캘린더 펼침
            applyCollapseProgress(0)
        }
        // p=1까지 매 프레임 동기 보간 (리스트 업 + 캘린더 압축)
        animateProgress(to: 1)
    }

    /// 패널을 닫고 그리드 복원 (월 전환 등 컨텍스트 변경 시).
    private func hideSchedulePanel() {
        guard isPanelVisible else { return }
        settlePanel(to: 0)
    }

    /// 드래그 종료 시 0/1로 정돈. 0이면 닫고 숨김(stepProgress 완료 시).
    private func settlePanel(to target: CGFloat) {
        animateProgress(to: target)
    }

    // 이전/다음 달 스냅샷
    private var prevMonthSnapshot: UIView?

    /// 패널이 올라온 상태에서의 좌우 스와이프 → 가벼운 월 전환 + 새 달 1일 선택(패널 유지).
    private func handlePanelMonthSwipe(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .ended, .cancelled:
            let tx = gesture.translation(in: calendarView).x
            let vx = gesture.velocity(in: calendarView).x
            let threshold = calendarView.bounds.width * 0.3
            guard abs(tx) > threshold || abs(vx) > 500 else { return }
            let delta = (tx < 0 || (tx == 0 && vx < 0)) ? 1 : -1 // 왼쪽 스와이프 = 다음 달
            changeMonthKeepingPanel(by: delta)
        default:
            break
        }
    }

    /// 월을 delta만큼 바꾸고, 그 달 1일을 선택한 것처럼 패널/캘린더를 갱신(접힘 유지).
    private func changeMonthKeepingPanel(by delta: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: delta, to: currentDate) else { return }
        currentDate = newDate

        var comps = Calendar.current.dateComponents([.year, .month], from: newDate)
        comps.day = 1
        guard let firstDay = Calendar.current.date(from: comps) else { return }
        selectedDate = firstDay

        // 새 달 데이터로 재구성(가로 슬라이드 페이드로 부드럽게). 접힘 상태는 cellForItemAt가 유지.
        UIView.transition(with: calendarView.collectionView, duration: 0.22,
                          options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.generateCalendar(updateHeader: false)
        }
        updateMonthLabel(animated: true)
        applyCollapseProgress(collapseProgress) // 새 가시 셀에 접힘 즉시 반영
        schedulePanelVC.update(date: firstDay, viewModel: viewModel)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        // 패널이 올라온(접힘) 상태에서는 스냅샷 월전환(풀 캘린더 전제)이 레이아웃을 깨므로,
        // 가벼운 월 전환 + 해당 달 1일 선택으로 대체한다.
        if isPanelVisible {
            handlePanelMonthSwipe(gesture)
            return
        }

        let collectionView = calendarView.collectionView
        let containerWidth = calendarView.bounds.width
        let translation = gesture.translation(in: collectionView)

        switch gesture.state {
        case .began:
            panStartLocation = gesture.location(in: collectionView)
            isTransitioning = true

            // 컬렉션 뷰의 부모 뷰에서의 위치 계산 (픽셀 정렬)
            let rawFrame = collectionView.convert(collectionView.bounds, to: calendarView)
            let collectionViewFrame = CGRect(
                x: rawFrame.origin.x.rounded(.down),
                y: rawFrame.origin.y.rounded(.down),
                width: rawFrame.width.rounded(.up),
                height: rawFrame.height.rounded(.up)
            )

            // 현재 달력 스냅샷 생성
            snapshotView = collectionView.snapshotView(afterScreenUpdates: false)
            if let snapshot = snapshotView {
                snapshot.frame = collectionViewFrame
                snapshot.clipsToBounds = true // 클리핑 설정
                calendarView.addSubview(snapshot)
            }

            // 이전/다음 달 스냅샷 미리 생성
            createAdjacentMonthSnapshots(collectionView: collectionView, collectionViewFrame: collectionViewFrame)

            // 실제 collectionView 숨김
            collectionView.alpha = 0

        case .changed:
            guard let snapshot = snapshotView else { return }

            // 현재 달력 스냅샷 이동 (손가락 따라가기 - 약간의 저항감으로 더 자연스럽게)
            // 저항감: 이동 거리가 멀수록 약간 느려지도록 (0.95 배율)
            let resistance: CGFloat = 0.95
            let adjustedTranslation = translation.x * resistance
            snapshot.transform = CGAffineTransform(translationX: adjustedTranslation, y: 0)

            // 다음 달 스냅샷 위치 (오른쪽에서 들어옴)
            if let nextSnapshot = nextMonthSnapshot {
                nextSnapshot.transform = CGAffineTransform(translationX: containerWidth + adjustedTranslation, y: 0)
            }

            // 이전 달 스냅샷 위치 (왼쪽에서 들어옴)
            if let prevSnapshot = prevMonthSnapshot {
                prevSnapshot.transform = CGAffineTransform(translationX: -containerWidth + adjustedTranslation, y: 0)
            }

        case .ended, .cancelled:
            guard let snapshot = snapshotView else {
                isTransitioning = false
                return
            }

            let velocity = gesture.velocity(in: collectionView)
            let progress = abs(translation.x) / containerWidth

            // 스와이프 방향 결정 (속도 또는 거리 기반)
            let shouldComplete = progress > swipeThreshold || abs(velocity.x) > 500
            let isSwipingLeft = translation.x < 0 || (translation.x == 0 && velocity.x < 0)

            if shouldComplete {
                // 월 전환 완료
                if isSwipingLeft {
                    guard let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else {
                        cancelTransition(snapshot: snapshot, collectionView: collectionView)
                        return
                    }
                    completeInteractiveTransition(currentSnapshot: snapshot, collectionView: collectionView, newDate: newDate, direction: .left)
                } else {
                    guard let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) else {
                        cancelTransition(snapshot: snapshot, collectionView: collectionView)
                        return
                    }
                    completeInteractiveTransition(currentSnapshot: snapshot, collectionView: collectionView, newDate: newDate, direction: .right)
                }
            } else {
                cancelTransition(snapshot: snapshot, collectionView: collectionView)
            }

        default:
            break
        }
    }

    /// 이전/다음 달 스냅샷을 미리 생성
    private func createAdjacentMonthSnapshots(collectionView: UICollectionView, collectionViewFrame: CGRect) {
        let containerWidth = calendarView.bounds.width
        let originalDate = currentDate
        let originalWeeks = weeks

        // 다음 달 스냅샷 생성
        if let nextDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = nextDate
            generateCalendarData()
            collectionView.reloadData()
            // 레이아웃 완전히 계산되도록 강제
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
            
            nextMonthSnapshot = collectionView.snapshotView(afterScreenUpdates: true)
            if let nextSnapshot = nextMonthSnapshot {
                nextSnapshot.frame = collectionViewFrame // 정확한 위치에 배치
                nextSnapshot.clipsToBounds = true // 클리핑 설정
                nextSnapshot.transform = CGAffineTransform(translationX: containerWidth, y: 0)
                calendarView.insertSubview(nextSnapshot, belowSubview: snapshotView ?? collectionView)
            }
        }

        // 이전 달 스냅샷 생성
        if let prevDate = Calendar.current.date(byAdding: .month, value: -1, to: originalDate) {
            currentDate = prevDate
            generateCalendarData()
            collectionView.reloadData()
            // 레이아웃 완전히 계산되도록 강제
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
            
            prevMonthSnapshot = collectionView.snapshotView(afterScreenUpdates: true)
            if let prevSnapshot = prevMonthSnapshot {
                prevSnapshot.frame = collectionViewFrame // 정확한 위치에 배치
                prevSnapshot.clipsToBounds = true // 클리핑 설정
                prevSnapshot.transform = CGAffineTransform(translationX: -containerWidth, y: 0)
                calendarView.insertSubview(prevSnapshot, belowSubview: snapshotView ?? collectionView)
            }
        }

        // 원래 데이터로 복원
        currentDate = originalDate
        weeks = originalWeeks
        collectionView.reloadData()
    }

    /// 인터랙티브 전환 완료
    private func completeInteractiveTransition(currentSnapshot: UIView, collectionView: UICollectionView, newDate: Date, direction: SlideDirection) {
        let containerWidth = calendarView.bounds.width
        let targetSnapshot = direction == .left ? nextMonthSnapshot : prevMonthSnapshot
        let otherSnapshot = direction == .left ? prevMonthSnapshot : nextMonthSnapshot

        // 월이 바뀌면 선택/패널 컨텍스트 정리
        selectedDate = nil
        selectedIndexPath = nil
        hideSchedulePanel()

        // 새 달력 데이터로 업데이트
        currentDate = newDate
        generateCalendar(updateHeader: false)
        collectionView.alpha = 1
        collectionView.transform = .identity

        // 슬라이드 완료 애니메이션 (스프링 효과로 부드러운 밀어내기 느낌)
        let exitOffset: CGFloat = direction == .left ? -containerWidth : containerWidth
        let otherOffset: CGFloat = direction == .left ? -containerWidth * 2 : containerWidth * 2
        
        // 스프링 애니메이션으로 더 자연스러운 느낌
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.85, // 감쇠 비율 (높을수록 덜 튐)
            initialSpringVelocity: 0.3,   // 초기 속도
            options: [.curveEaseOut]
        ) {
            // 현재 달력은 반대 방향으로 밀려나감
            currentSnapshot.transform = CGAffineTransform(translationX: exitOffset, y: 0)

            // 대상 달력은 제자리로 (스프링 효과)
            targetSnapshot?.transform = .identity

            // 반대쪽 스냅샷은 더 멀리
            otherSnapshot?.transform = CGAffineTransform(translationX: otherOffset, y: 0)
        } completion: { _ in
            currentSnapshot.removeFromSuperview()
            self.snapshotView = nil
            self.nextMonthSnapshot?.removeFromSuperview()
            self.nextMonthSnapshot = nil
            self.prevMonthSnapshot?.removeFromSuperview()
            self.prevMonthSnapshot = nil
            self.isTransitioning = false
        }

        updateMonthLabel(animated: true)
    }

    /// 달력 데이터만 생성 (UI reloadData 없이)
    private func generateCalendarData() {
        weeks = []

        var calendar = Calendar.current
        calendar.firstWeekday = 1

        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekdayIndex = (weekday + 6) % 7

        let numberOfDays = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30

        // 첫 주 생성 (빈 날짜 + 실제 날짜)
        var currentWeek: [WeekDayInfo] = []

        // 빈 날짜들 추가
        for _ in 0..<firstWeekdayIndex {
            currentWeek.append(createEmptyDayInfo())
        }

        // 첫 주의 실제 날짜들 추가
        let daysInFirstWeek = 7 - firstWeekdayIndex
        for day in 1...daysInFirstWeek {
            let dayInfo = createDayInfo(day: day, components: components, calendar: calendar)
            currentWeek.append(dayInfo)
        }
        weeks.append(currentWeek)

        // 나머지 주들 생성
        var currentDay = daysInFirstWeek + 1
        while currentDay <= numberOfDays {
            currentWeek = []
            let daysInThisWeek = min(7, numberOfDays - currentDay + 1)

            for day in currentDay..<(currentDay + daysInThisWeek) {
                let dayInfo = createDayInfo(day: day, components: components, calendar: calendar)
                currentWeek.append(dayInfo)
            }

            // 주가 7일이 안 되면 빈 날짜로 채움
            while currentWeek.count < 7 {
                currentWeek.append(createEmptyDayInfo())
            }

            weeks.append(currentWeek)
            currentDay += daysInThisWeek
        }
    }

    private func cancelTransition(snapshot: UIView, collectionView: UICollectionView) {
        let containerWidth = calendarView.bounds.width

        // 원위치로 복귀 애니메이션 (스프링 효과로 자연스럽게)
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,  // 감쇠 비율
            initialSpringVelocity: 0.5,   // 초기 속도
            options: [.curveEaseOut]
        ) {
            // 현재 달력 원위치로
            snapshot.transform = .identity
            // 다음 달 스냅샷은 오른쪽 밖으로
            self.nextMonthSnapshot?.transform = CGAffineTransform(translationX: containerWidth, y: 0)
            // 이전 달 스냅샷은 왼쪽 밖으로
            self.prevMonthSnapshot?.transform = CGAffineTransform(translationX: -containerWidth, y: 0)
        } completion: { _ in
            snapshot.removeFromSuperview()
            self.snapshotView = nil
            self.nextMonthSnapshot?.removeFromSuperview()
            self.nextMonthSnapshot = nil
            self.prevMonthSnapshot?.removeFromSuperview()
            self.prevMonthSnapshot = nil
            collectionView.alpha = 1
            self.isTransitioning = false
        }
    }

    @objc private func icloudDidUpdate(notification: Notification) {
        //viewModel.loadAllTodos()
        DispatchQueue.main.async {
            self.calendarView.collectionView.reloadData()
            self.schedulePanelVC.refreshIfVisible()
        }
    }

    /// 외부 캘린더 일정이 갱신되면 달력·패널을 다시 그린다.
    /// weeks 데이터는 캐시이므로 reloadData만으로는 부족 — todos(for:)로 다시 생성해야 한다.
    @objc private func externalTodosUpdated() {
        DispatchQueue.main.async {
            self.generateCalendar(updateHeader: false)
            self.schedulePanelVC.refreshIfVisible()
        }
    }

    @objc private func forceSync() {
        NSUbiquitousKeyValueStore.default.synchronize()
        // 앱 복귀 시 Live Activity를 다시 동기화한다. 백그라운드 동안 종료된 일정은
        // 타이머가 멈춰 있어 '진행 중'으로 남아 있으므로, 여기서 종료/다음으로 전환한다.
        #if canImport(NowerCore)
        refreshLiveActivity()
        #endif
    }

    private func preloadAdjacentMonths(baseDate: Date) {
        holidayUseCase.preloadAdjacentMonths(baseDate: baseDate, completion: {
            DispatchQueue.main.async {
                self.calendarView.collectionView.reloadData()
            }
        })
    }

    private func generateCalendar(updateHeader: Bool = true) {
        weeks = []

        var calendar = Calendar.current
        calendar.firstWeekday = 1

        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekdayIndex = (weekday + 6) % 7

        let numberOfDays = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30

        // 첫 주 생성 (빈 날짜 + 실제 날짜)
        var currentWeek: [WeekDayInfo] = []
        
        // 빈 날짜들 추가
        for _ in 0..<firstWeekdayIndex {
            currentWeek.append(createEmptyDayInfo())
        }

        // 첫 주의 실제 날짜들 추가
        let daysInFirstWeek = 7 - firstWeekdayIndex
        for day in 1...daysInFirstWeek {
            let dayInfo = createDayInfo(day: day, components: components, calendar: calendar)
            currentWeek.append(dayInfo)
        }
        weeks.append(currentWeek)

        // 나머지 주들 생성
        var currentDay = daysInFirstWeek + 1
        while currentDay <= numberOfDays {
            currentWeek = []
            let daysInThisWeek = min(7, numberOfDays - currentDay + 1)
            
            for day in currentDay..<(currentDay + daysInThisWeek) {
                let dayInfo = createDayInfo(day: day, components: components, calendar: calendar)
                currentWeek.append(dayInfo)
            }
            
            // 주가 7일이 안 되면 빈 날짜로 채움
            while currentWeek.count < 7 {
                currentWeek.append(createEmptyDayInfo())
            }
            
            weeks.append(currentWeek)
            currentDay += daysInThisWeek
        }

        if updateHeader {
            updateMonthLabel(animated: false)
        }
        recomputeMonthDensity()
        calendarView.collectionView.reloadData()
        updateDensityCard()
        #if canImport(NowerCore)
        refreshLiveActivity()
        #endif

        if let year = components.year, let month = components.month {
            holidayUseCase.fetchHolidays(for: year, month: month) { _ in
                DispatchQueue.main.async {
                    self.calendarView.collectionView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Density Card (하루 밀도)

    private func setupDensityCard() {
        #if canImport(NowerCore)
        // DayView 히트맵 틴트가 읽어갈 밴드맵 공급자 주입
        DayView.densityBandHexProvider = { [weak self] key in
            self?.densityBandHexByDate[key]
        }
        let host = UIHostingController(rootView: makeChip(state: densityViewState()))
        host.view.backgroundColor = .clear
        addChild(host)
        calendarView.densityChipContainer.addSubview(host.view)
        host.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        // 빈 컨테이너엔 intrinsic size가 없어 우선순위가 무의미 → 실제 콘텐츠(host.view)에 적용.
        // 명언 라벨(750)과의 경쟁에서 칩이 이겨 내부 텍스트가 잘리지 않도록.
        host.view.setContentHuggingPriority(.required, for: .horizontal)
        host.view.setContentCompressionResistancePriority(.required, for: .horizontal)
        host.didMove(toParent: self)
        densityChipHostingController = host
        #endif
    }

    /// 선택 날짜(없으면 오늘)의 밀도 칩을 갱신
    private func updateDensityCard() {
        #if canImport(NowerCore)
        densityChipHostingController?.rootView = makeChip(state: densityViewState())
        #endif
    }

    #if canImport(NowerCore)
    private func makeChip(state: DensityViewState) -> DensityChipView {
        DensityChipView(state: state) { [weak self] in
            self?.presentDensityDetail()
        }
    }

    private func densityViewState() -> DensityViewState {
        let day = selectedDate ?? Date()
        let reflections = DependencyContainer.shared.reflectionStore.all()
        // 자기상대 표현: 지난 30일 개인 분포 대비로 칩/카드 의미를 만든다.
        return NowerDensity.relativeViewState(
            todosProvider: { [weak self] in self?.viewModel.todos(for: $0) ?? [] },
            day: day,
            reflections: reflections
        )
    }

    /// 오늘 "다음 시간 일정"으로 Live Activity Companion을 동기화. 없으면 종료.
    /// (정확한 시간 알림은 Local Notification 담당 — 여기는 보조 카운트다운)
    #if canImport(NowerCore)
    func refreshLiveActivity() {
        guard #available(iOS 16.2, *) else { return }
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        let todos = viewModel.todos(for: today)

        // 시간 일정의 (todo, 시작, 종료) — 종료는 실제 값(없으면 +1시간)
        let timed = todos.compactMap { todo -> (todo: TodoItem, start: Date, end: Date)? in
            guard let t = todo.scheduledTime, let start = TodoItem.combineTime(t, with: today) else { return nil }
            return (todo, start, Self.liveActivityEnd(of: todo, start: start, today: today))
        }

        // 진행 중(지금 구간 안)을 다음 예정보다 우선한다. 진행 중이 여러 개면 먼저 끝나는 것.
        let ongoing = timed.filter { $0.start <= now && now < $0.end }.min { $0.end < $1.end }
        let next = timed.filter { $0.start > now }.min { $0.start < $1.start }

        let densityLabel = NowerDensity.report(todos: todos, day: today).band.label

        let state: NowerLiveActivityAttributes.ContentState?
        if let o = ongoing {
            state = NowerLiveActivityAttributes.ContentState(
                eventTitle: o.todo.text,
                eventDate: o.end,                       // 종료까지 카운트다운
                startTime: o.todo.scheduledTime ?? "",
                mode: .inProgress,
                detail: "~\(o.todo.endScheduledTime ?? Self.hhmm(o.end)) 종료"
            )
        } else if let n = next {
            state = NowerLiveActivityAttributes.ContentState(
                eventTitle: n.todo.text,
                eventDate: n.start,
                startTime: n.todo.scheduledTime ?? "",
                mode: .upcoming
            )
        } else {
            state = nil
        }

        NowerLiveActivityManager.shared.sync(densityLabel: densityLabel, state: state)
        scheduleBoundaryRefresh(todos: todos, now: now, today: today)
    }

    /// 시간 일정의 종료 Date — 실제 종료 시각(있으면) / 없으면 시작 +1시간.
    private static func liveActivityEnd(of todo: TodoItem, start: Date, today: Date) -> Date {
        if let e = todo.endScheduledTime, let end = TodoItem.combineTime(e, with: today), end > start { return end }
        return start.addingTimeInterval(3600)
    }

    /// Date → "HH:mm"
    private static func hhmm(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    /// 다음 일정 경계(시작/끝)가 도래하면 Live Activity·위젯을 다시 동기화한다.
    /// 포그라운드에서 시간이 흐를 때 멈춰 있지 않고 다음 일정으로 전환되도록 한다.
    /// (백그라운드 자동 전환은 push가 필요 — 여기서는 다루지 않음. 위젯은 타임라인 엔트리로 자체 전환.)
    private func scheduleBoundaryRefresh(todos: [TodoItem], now: Date, today: Date) {
        boundaryTimer?.invalidate()
        boundaryTimer = nil

        // 오늘 시간 일정들의 시작/끝 시각 중 'now 이후' 가장 가까운 경계
        var boundaries: [Date] = []
        for todo in todos {
            guard let t = todo.scheduledTime,
                  let start = TodoItem.combineTime(t, with: today) else { continue }
            if start > now { boundaries.append(start) }
            let end = Self.liveActivityEnd(of: todo, start: start, today: today)
            if end > now { boundaries.append(end) }
        }
        guard let next = boundaries.min() else { return }

        let interval = max(1, next.timeIntervalSince(now))
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            self?.refreshLiveActivity()
            WidgetCenter.shared.reloadAllTimelines()
        }
        timer.tolerance = 5
        RunLoop.main.add(timer, forMode: .common)
        boundaryTimer = timer
    }
    #endif

    /// 현재 표시 월의 일별 밀도를 계산해 히트맵 밴드맵 갱신
    private func recomputeMonthDensity() {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        let comps = calendar.dateComponents([.year, .month], from: currentDate)
        guard let first = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: currentDate) else { return }
        let days: [Date] = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
        let report = NowerDensity.monthReport(days: days) { [weak self] date in
            self?.viewModel.todos(for: date) ?? []
        }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        var map: [String: String] = [:]
        for date in days {
            let key = f.string(from: date)
            // 여유(light)는 제외 — 주의가 필요한 보통/과부하만 dot 표기 (차분 유지)
            if let band = report.band(forDateKey: key), band != .light {
                map[key] = band.colorHex
            }
        }
        densityBandHexByDate = map
    }

    /// 칩 탭 → 상세 밀도 카드 + 체감 캡처 + 월간 리포트 진입 바텀 시트
    private func presentDensityDetail() {
        let day = selectedDate ?? Date()
        let todos = viewModel.todos(for: day)
        let store = DependencyContainer.shared.reflectionStore
        let reflections = store.all()

        let state = NowerDensity.relativeViewState(
            todosProvider: { [weak self] in self?.viewModel.todos(for: $0) ?? [] },
            day: day,
            reflections: reflections
        )
        // 보정 전(raw) 예측 — 체감 기록의 기준값
        let base = NowerDensity.report(todos: todos, day: day)

        let cal = Calendar.current
        let canReflect = cal.startOfDay(for: day) <= cal.startOfDay(for: Date()) && !todos.isEmpty
        let existing = store.reflection(for: day)?.feltBand

        let sheet = DensityDetailSheet(
            densityState: state,
            dayTitle: reflectionDayTitle(for: day),
            canReflect: canReflect,
            existingFelt: existing,
            onSaveReflection: { [weak self] band, note in
                self?.saveReflection(day: day, feltBand: band, note: note, predicted: base)
            },
            onOpenMonthlyReport: { [weak self] in
                self?.presentMonthlyReport()
            }
        )
        let host = UIHostingController(rootView: sheet)
        if let sh = host.sheetPresentationController {
            sh.detents = [.medium(), .large()]
            sh.prefersGrabberVisible = true
        }
        present(host, animated: true)
        // 카드를 열어 마일스톤을 봤으니 '알림 완료' 처리(다시 안 뜸)
        NowerDensity.acknowledgeMilestones(
            todosProvider: { [weak self] in self?.viewModel.todos(for: $0) ?? [] },
            day: day,
            reflections: reflections
        )
    }

    /// 하루 끝 체감 1탭 저장 → 보정 루프 입력. 저장 후 칩/히트맵 갱신.
    private func saveReflection(day: Date, feltBand: DensityBand, note: String?, predicted: DensityReport) {
        let reflection = DayReflection(
            date: Calendar.current.startOfDay(for: day),
            feltBand: feltBand,
            predictedScore: predicted.score,
            predictedBand: predicted.band,
            note: note,
            createdAt: Date()
        )
        DependencyContainer.shared.reflectionStore.upsert(reflection)
        updateDensityCard()
    }

    /// 월간 에너지 리포트 시트 표시 (현재 표시 월 기준)
    private func presentMonthlyReport() {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        let month = currentDate
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let first = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: month) else { return }
        let days: [Date] = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
        let reflections = DependencyContainer.shared.reflectionStore.all()
        let report = NowerDensity.monthlyEnergyReport(
            month: month,
            days: days,
            todosProvider: { [weak self] date in self?.viewModel.todos(for: date) ?? [] },
            reflections: reflections
        )
        let view = MonthlyEnergyReportView(report: report, monthTitle: month.formatted("yyyy년 M월"))
        let host = UIHostingController(rootView: view)
        if let sh = host.sheetPresentationController {
            sh.detents = [.large()]
            sh.prefersGrabberVisible = true
        }
        // 상세 시트 위에 올림
        (presentedViewController ?? self).present(host, animated: true)
    }

    private func reflectionDayTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "오늘" }
        if cal.isDateInYesterday(date) { return "어제" }
        return date.formatted("M월 d일")
    }
    #endif

    private func createDayInfo(day: Int, components: DateComponents, calendar: Calendar) -> WeekDayInfo {
        var dayComponents = components
        dayComponents.day = day
        guard let date = calendar.date(from: dayComponents) else {
            return createEmptyDayInfo()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let todos = viewModel.todos(for: date)
        let today = Date()
        let isToday = calendar.isDate(today, inSameDayAs: date)
        let holidayName = holidayUseCase.holidayName(for: date)
        let weekday = calendar.component(.weekday, from: date)
        let isSunday = weekday == 1
        let isSaturday = weekday == 7
        
        return WeekDayInfo(
            day: day,
            dateString: dateString,
            todos: todos,
            isToday: isToday,
            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
            holidayName: holidayName,
            isSunday: isSunday,
            isSaturday: isSaturday
        )
    }
    
    private func createEmptyDayInfo() -> WeekDayInfo {
        return WeekDayInfo(
            day: nil,
            dateString: "",
            todos: [],
            isToday: false,
            isSelected: false,
            holidayName: nil,
            isSunday: false,
            isSaturday: false
        )
    }

    private func updateMonthLabel(animated: Bool = false) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        let text = formatter.string(from: currentDate)

        guard animated else {
            calendarView.monthLabel.text = text
            return
        }

        calendarView.monthLabel.layer.removeAllAnimations()
        UIView.transition(
            with: calendarView.monthLabel,
            duration: 0.22,
            options: [.transitionCrossDissolve, .beginFromCurrentState, .allowUserInteraction]
        ) {
            self.calendarView.monthLabel.text = text
        }
    }

    @objc private func didTapPreviousMonth() {
        if isPanelVisible { changeMonthKeepingPanel(by: -1); return }
        guard let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) else { return }
        animateMonthTransition(to: newDate, direction: .right)
    }

    @objc private func didTapNextMonth() {
        if isPanelVisible { changeMonthKeepingPanel(by: 1); return }
        guard let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else { return }
        animateMonthTransition(to: newDate, direction: .left)
    }

    private func animateMonthTransition(to newDate: Date, direction: SlideDirection) {
        // 월을 바꾸면 이전 달의 선택 날짜 맥락을 정리한다 (UX 검토 §2):
        // 밀도 칩이 "오늘" 기준으로 돌아가 어느 달의 선택인지 혼란 없앰.
        selectedDate = nil
        selectedIndexPath = nil
        hideSchedulePanel()

        let collectionView = calendarView.collectionView
        let containerWidth = calendarView.bounds.width

        // 컬렉션 뷰의 부모 뷰에서의 위치 계산 (픽셀 정렬)
        let rawFrame = collectionView.convert(collectionView.bounds, to: calendarView)
        let collectionViewFrame = CGRect(
            x: rawFrame.origin.x.rounded(.down),
            y: rawFrame.origin.y.rounded(.down),
            width: rawFrame.width.rounded(.up),
            height: rawFrame.height.rounded(.up)
        )

        // 스냅샷 생성 (현재 달력)
        guard let snapshot = collectionView.snapshotView(afterScreenUpdates: false) else {
            currentDate = newDate
            generateCalendar()
            return
        }

        snapshot.frame = collectionViewFrame // 정확한 위치에 배치
        snapshot.clipsToBounds = true // 클리핑 설정
        calendarView.addSubview(snapshot)

        // 새 달력 데이터로 업데이트
        currentDate = newDate
        generateCalendar(updateHeader: false)

        // 새 달력 초기 위치 설정 (화면 밖)
        let offsetX: CGFloat = direction == .left ? containerWidth : -containerWidth
        collectionView.transform = CGAffineTransform(translationX: offsetX, y: 0)

        // 슬라이드 애니메이션 (스프링 효과로 부드러운 밀어내기 느낌)
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.85, // 감쇠 비율 (높을수록 덜 튐)
            initialSpringVelocity: 0.3,   // 초기 속도
            options: [.curveEaseOut]
        ) {
            // 기존 달력 밀려나감
            snapshot.transform = CGAffineTransform(translationX: -offsetX, y: 0)
            // 새 달력 들어옴
            collectionView.transform = .identity
        } completion: { _ in
            snapshot.removeFromSuperview()
        }

        updateMonthLabel(animated: true)
    }

    private enum SlideDirection {
        case left, right
    }

    /// Todo 데이터가 업데이트되었을 때 UI를 새로고침합니다.
    /// CloudSyncManager에서 발송하는 알림을 수신하여 처리합니다.
    @objc private func todosUpdated() {
        DispatchQueue.main.async {
            // ViewModel의 데이터를 새로 로드
            self.viewModel.loadAllTodos()
            // 달력 데이터 재생성 (주 단위로 그룹화)
            self.generateCalendar()
            // 패널이 열려 있으면 동일 날짜로 리스트 갱신
            self.schedulePanelVC.refreshIfVisible()
        }
    }
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weeks.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 주 단위 셀 선택은 WeekView의 touchesEnded에서 처리됨
        // 이 메서드는 빈 구현으로 두거나, 필요시 추가 처리 가능
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Separator 제거 - 셀 간격 없이 연결된 느낌을 위해
        if let separator = cell.contentView.viewWithTag(999) {
            separator.removeFromSuperview()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WeekCell.identifier, for: indexPath) as? WeekCell else {
            return UICollectionViewCell()
        }

        guard indexPath.item < weeks.count else { return cell }
        
        let week = weeks[indexPath.item]
        
        cell.configure(weekDays: week)

        // 날짜 선택 콜백 설정
        cell.onDaySelected = { [weak self] dateString in
            self?.handleDaySelection(dateString: dateString)
        }

        // 일정 선택 콜백 설정 (기간별 일정 터치 시)
        cell.onTodoSelected = { [weak self] todo, dateString in
            self?.handleTodoSelection(todo: todo, dateString: dateString)
        }

        cell.onMoreTapped = { [weak self] dateString, _ in
            self?.handleDaySelection(dateString: dateString)
        }

        // 재사용 셀에 현재 접힘 진행도 주입 (드래그 중 reloadData 없이도 일관)
        cell.collapseProgress = collapseProgress

        return cell
    }

    private func handleTodoSelection(todo: TodoItem, dateString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let selectedDate = formatter.date(from: dateString) else { return }

        coordinator?.presentEditEvent(todo: todo, date: selectedDate, viewModel: viewModel)
    }

    private func handleDaySelection(dateString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let selectedDate = formatter.date(from: dateString) else { return }

        self.selectedDate = selectedDate
        generateCalendar()
        // 모달 제거 → 인라인 하단 패널로 표시 (2-depth)
        showSchedulePanel(for: selectedDate)
    }
}

extension CalendarViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 주 단위 셀: 전체 너비 사용, 높이는 실제 주 개수에 맞게 동적 계산
        let availableWidth = collectionView.bounds.width
        let availableHeight = collectionView.bounds.height

        // 실제 주 개수로 높이 계산 (4주~6주)
        let numberOfWeeks = weeks.count
        guard numberOfWeeks > 0 else {
            return CGSize(width: availableWidth, height: 80)
        }

        // 사용 가능한 높이를 주 개수로 균등 분배
        let cellHeight = availableHeight / CGFloat(numberOfWeeks)

        return CGSize(width: availableWidth, height: cellHeight)
    }
}

// MARK: - UIGestureRecognizerDelegate (가로 월전환 vs 세로 패널 방향 게이트)

extension CalendarViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        if isTransitioning { return false } // 월 전환 중 상호 배제
        let v = pan.velocity(in: calendarView)
        if pan === verticalPan {
            return abs(v.y) > abs(v.x)
        }
        if pan === horizontalPan {
            return abs(v.x) >= abs(v.y)
        }
        return true
    }
}

// MARK: - SchedulePanelDelegate

extension CalendarViewController: SchedulePanelDelegate {
    func schedulePanel(_ panel: SchedulePanelViewController, didDragToProgress progress: CGFloat) {
        progressLink?.invalidate(); progressLink = nil // 드래그가 애니메이션 인수
        applyCollapseProgress(progress)
    }

    func schedulePanel(_ panel: SchedulePanelViewController, didEndDraggingWithProgress progress: CGFloat, velocity: CGFloat) {
        let target: CGFloat
        if abs(velocity) > 800 {
            target = velocity < 0 ? 1 : 0 // 위로 빠르게 = 확장, 아래로 = peek
        } else {
            target = progress > 0.5 ? 1 : 0
        }
        settlePanel(to: target)
    }

    func schedulePanelDidRequestAdd(_ panel: SchedulePanelViewController) {
        let date = selectedDate ?? Date()
        coordinator?.presentNewEvent(for: date, viewModel: viewModel)
    }

    func schedulePanel(_ panel: SchedulePanelViewController, didSelect todo: TodoItem, on date: Date) {
        coordinator?.presentEditEvent(todo: todo, date: date, viewModel: viewModel)
    }
}
