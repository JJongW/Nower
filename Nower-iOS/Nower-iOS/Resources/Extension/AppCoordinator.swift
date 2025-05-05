//
//  AppCoordinator.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/6/25.
//

import UIKit

final class AppCoordinator {
    let window: UIWindow
    let navigationController: UINavigationController

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.navigationController.isNavigationBarHidden = true
    }

    func start() {
        let calendarVC = makeCalendarViewController()
        calendarVC.coordinator = self
        navigationController.viewControllers = [calendarVC]
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
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
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        navigationController.present(newEventVC, animated: true)
    }

    func presentEventList(for date: Date, viewModel: CalendarViewModel) {
        let listVC = EventListViewController()
        listVC.selectedDate = date
        listVC.viewModel = viewModel
        listVC.coordinator = self
        navigationController.topViewController?.present(listVC, animated: true)
    }

    func returnToBack() {
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true)
        } else {
            navigationController.popViewController(animated: true)
        }
    }
}
