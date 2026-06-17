//
//  AppCoordinator.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/6/25.
//

import UIKit
// NOTE: Import NowerCore when package is linked
// import NowerCore

final class AppCoordinator {
    let window: UIWindow
    let navigationController: UINavigationController

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.navigationController.isNavigationBarHidden = true
    }

    func start() {
        // NowerCore 마이그레이션 실행
        // TODO: Uncomment when NowerCore package is linked
        // Task { @MainActor in
        //     DependencyContainer.shared.runMigrationIfNeeded()
        //     DependencyContainer.shared.startSyncListening()
        // }

        let calendarVC = makeCalendarViewController()
        calendarVC.coordinator = self
        navigationController.viewControllers = [calendarVC]
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        checkForUpdate()
    }

    /// App Store 최신 버전과 비교해 강제/권장 업데이트를 안내한다.
    /// 네트워크 실패 시에는 아무것도 막지 않는다(fail-open).
    private func checkForUpdate() {
        Task { @MainActor in
            let status = await AppUpdateChecker().check()
            switch status {
            case .upToDate:
                break
            case let .optional(storeVersion, url):
                presentOptionalUpdate(storeVersion: storeVersion, appStoreURL: url)
            case let .required(_, url):
                presentForceUpdate(appStoreURL: url)
            }
        }
    }

    private func presentForceUpdate(appStoreURL: URL) {
        let updateVC = ForceUpdateViewController(appStoreURL: appStoreURL)
        navigationController.present(updateVC, animated: true)
    }

    private func presentOptionalUpdate(storeVersion: String, appStoreURL: URL) {
        let alert = UIAlertController(
            title: "새 버전이 있어요",
            message: "버전 \(storeVersion)으로 업데이트하면 더 좋아져요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
        alert.addAction(UIAlertAction(title: "업데이트", style: .default) { _ in
            UIApplication.shared.open(appStoreURL)
        })
        navigationController.present(alert, animated: true)
    }

    private func makeCalendarViewController() -> CalendarViewController {
        let todoRepository = TodoRepositoryImpl()
        let holidayRepository = HolidayRepositoryImpl()
        let holidayUseCase = HolidayUseCaseImpl(repository: holidayRepository)

        let viewModel = CalendarViewModel(
            addTodoUseCase: DefaultAddTodoUseCase(repository: todoRepository),
            deleteTodoUseCase: DefaultDeleteTodoUseCase(repository: todoRepository),
            updateTodoUseCase: DefaultUpdateTodoUseCase(repository: todoRepository),
            getTodosByDateUseCase: DefaultGetTodosByDateUseCase(repository: todoRepository),
            loadAllTodosUseCase: DefaultLoadAllTodosUseCase(repository: todoRepository),
            holidayUseCase: holidayUseCase
        )

        let calendarVC = CalendarViewController(viewModel: viewModel, holidayUseCase: holidayUseCase)
        calendarVC.coordinator = self
        return calendarVC
    }

    func presentNewEvent(for date: Date, viewModel: CalendarViewModel) {
        let newEventVC = NewEventViewController()
        newEventVC.selectedDate = date
        newEventVC.viewModel = viewModel
        newEventVC.coordinator = self

        if let sheet = newEventVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        navigationController.present(newEventVC, animated: true)
    }

    func presentEventList(for date: Date, viewModel: CalendarViewModel) {
        let listVC = EventListViewController()
        listVC.selectedDate = date
        listVC.viewModel = viewModel
        listVC.coordinator = self
        if let sheet = listVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        navigationController.topViewController?.present(listVC, animated: true)
    }

    func presentEditEvent(todo: TodoItem, date: Date, viewModel: CalendarViewModel) {
        let editVC = EditEventBottomSheetViewController()
        editVC.todo = todo
        editVC.viewModel = viewModel
        editVC.selectedDate = date
        editVC.coordinator = self

        if let sheet = editVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        navigationController.topViewController?.present(editVC, animated: true)
    }

    /// 출발 알림 설정(집·회사 위치, 버퍼)을 띄운다.
    func presentDepartureSettings() {
        let settingsVC = DepartureSettingsViewController()
        let nav = UINavigationController(rootViewController: settingsVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        navigationController.present(nav, animated: true)
    }

    func returnToBack() {
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true)
        } else {
            navigationController.popViewController(animated: true)
        }
    }
}
