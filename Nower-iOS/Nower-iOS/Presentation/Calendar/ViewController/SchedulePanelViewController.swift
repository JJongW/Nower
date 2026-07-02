//
//  SchedulePanelViewController.swift
//  Nower-iOS
//
//  하단 인라인 일정 패널. CalendarViewController의 자식 VC.
//  모달 시트(EventListViewController)를 대체해 탭 깊이를 3 → 2로 줄인다.
//  세로 pan으로 peek↔expanded 보간하며, 진행도(progress)를 부모에 통지해
//  캘린더 그리드 접힘(collapse)과 동기화한다.
//

import UIKit
import NowerCore

protocol SchedulePanelDelegate: AnyObject {
    /// 드래그 중 연속 진행도(0 = peek, 1 = 확장). 부모가 높이/코스메틱 적용.
    func schedulePanel(_ panel: SchedulePanelViewController, didDragToProgress progress: CGFloat)
    /// 드래그 종료 — 부모가 0/1로 스프링 정돈.
    func schedulePanel(_ panel: SchedulePanelViewController, didEndDraggingWithProgress progress: CGFloat, velocity: CGFloat)
    /// "+" 탭 — 부모가 NewEvent 직행(2-depth).
    func schedulePanelDidRequestAdd(_ panel: SchedulePanelViewController)
    /// 행 탭 — 부모가 편집 시트 표시.
    func schedulePanel(_ panel: SchedulePanelViewController, didSelect todo: TodoItem, on date: Date)
}

final class SchedulePanelViewController: UIViewController {

    weak var delegate: SchedulePanelDelegate?

    private let panelView = SchedulePanelView()
    private var selectedDate: Date?
    private weak var viewModel: CalendarViewModel?

    /// 리스트가 완전히 올라왔을 때(p=1)의 패널 높이. 부모가 주입.
    var listHeight: CGFloat = 480

    /// 진행도(0 = 숨김/풀 캘린더, 1 = 리스트 업/점 그리드). 패널이 source of truth.
    private(set) var progress: CGFloat = 0 {
        didSet {
            // 확장 상태에서만 테이블 스크롤 허용 (그 외엔 드래그가 패널을 움직임)
            panelView.listView.eventTableView.isScrollEnabled = progress >= 0.999
        }
    }

    // 드래그 기준값
    private var dragStartProgress: CGFloat = 0

    override func loadView() {
        self.view = panelView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let table = panelView.listView.eventTableView
        table.dataSource = self
        table.delegate = self
        table.isScrollEnabled = false

        panelView.listView.addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        panelView.addGestureRecognizer(pan)
    }

    // MARK: - Public API

    /// 날짜/데이터 갱신 후 리스트를 다시 그린다.
    func update(date: Date, viewModel: CalendarViewModel) {
        self.selectedDate = date
        self.viewModel = viewModel
        reload()
    }

    /// 외부(데이터 변경)에서 현재 날짜로 새로고침.
    func refreshIfVisible() {
        guard selectedDate != nil, viewModel != nil else { return }
        reload()
    }

    /// 부모가 진행도를 적용한 뒤 패널 내부 상태(스크롤 가능 여부 등)를 맞추기 위해 호출.
    func syncProgress(_ p: CGFloat) {
        progress = max(0, min(1, p))
    }

    private func reload() {
        guard let date = selectedDate, let viewModel = viewModel else { return }
        viewModel.selectedDate = date
        viewModel.loadAllTodos()
        let todos = viewModel.todos(for: date)

        let list = panelView.listView
        list.eventTableView.reloadData()
        list.eventDateLabel.text = date.formatted("dd")
        list.eventWeekLabel.text = date.formattedUS("EEE.").uppercased()
        list.eventLabel.text = dateDescription(for: date)
        list.configure(date: date, eventCount: todos.count)
    }

    private func dateDescription(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "오늘" }
        if calendar.isDateInYesterday(date) { return "어제" }
        if calendar.isDateInTomorrow(date) { return "내일" }
        let dateYear = calendar.component(.year, from: date)
        let todayYear = calendar.component(.year, from: Date())
        return dateYear == todayYear ? date.formatted("M월") : date.formatted("yyyy.M월")
    }

    @objc private func didTapAdd() {
        delegate?.schedulePanelDidRequestAdd(self)
    }

    // MARK: - Pan

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let table = panelView.listView.eventTableView
        let translationY = gesture.translation(in: view).y
        let span = max(1, listHeight)

        switch gesture.state {
        case .began:
            dragStartProgress = progress
        case .changed:
            // 확장 상태에서 아래로 끌 때, 테이블이 위로 스크롤돼 있으면 패널 접힘을 시작하지 않음
            if dragStartProgress >= 0.999 && translationY > 0 && table.contentOffset.y > 0 {
                gesture.setTranslation(.zero, in: view)
                dragStartProgress = 1
                return
            }
            // 위로 끌면(translationY < 0) 진행도 증가
            let candidate = dragStartProgress + (-translationY / span)
            progress = max(0, min(1, candidate))
            delegate?.schedulePanel(self, didDragToProgress: progress)
        case .ended, .cancelled:
            let velocityY = gesture.velocity(in: view).y
            delegate?.schedulePanel(self, didEndDraggingWithProgress: progress, velocity: velocityY)
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SchedulePanelViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let v = pan.velocity(in: view)
        // 세로 의도일 때만 (가로 월 전환과 무충돌)
        return abs(v.y) >= abs(v.x)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        // 테이블 스크롤과 동시 인식 (확장 상태에서 스크롤 우선 처리)
        return true
    }
}

// MARK: - UITableViewDataSource / Delegate

extension SchedulePanelViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let date = selectedDate, let viewModel = viewModel else { return 0 }
        return viewModel.todos(for: date).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as? EventTableViewCell,
              let date = selectedDate, let viewModel = viewModel else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.todos(for: date)[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let date = selectedDate, let viewModel = viewModel else { return }
        let todo = viewModel.todos(for: date)[indexPath.row]
        delegate?.schedulePanel(self, didSelect: todo, on: date)
    }
}
