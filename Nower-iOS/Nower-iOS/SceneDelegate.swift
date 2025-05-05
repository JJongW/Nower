//
//  SceneDelegate.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/17/25.
//

import Foundation
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func testICloudKeyValueStoreSave() {
        let store = NSUbiquitousKeyValueStore.default

        struct DummyTodo: Codable {
            let text: String
            let isRepeating: Bool
            let date: String
            let colorName: String
        }

        let dummy = DummyTodo(text: "iCloud Test", isRepeating: false, date: "2025-05-03", colorName: "skyblue")

        do {
            let data = try JSONEncoder().encode(dummy)
            store.set(data, forKey: "iCloudTestTodo")
            let result = store.synchronize()
            print("✅ iCloud 저장 시도됨, 동기화 결과: \(result)")
        } catch {
            print("❌ iCloud 인코딩/저장 실패: \(error)")
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        testICloudKeyValueStoreSave()
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // ✅ 저장소 및 유스케이스 인스턴스 생성
        let todoRepository = TodoRepositoryImpl()
        let holidayRepository = HolidayRepositoryImpl()
        let holidayUseCase = HolidayUseCaseImpl(repository: holidayRepository)

        // ✅ 뷰모델 주입
        let viewModel = CalendarViewModel(
            addTodoUseCase: DefaultAddTodoUseCase(repository: todoRepository),
            deleteTodoUseCase: DefaultDeleteTodoUseCase(repository: todoRepository),
            updateTodoUseCase: DefaultUpdateTodoUseCase(repository: todoRepository),
            getTodosByDateUseCase: DefaultGetTodosByDateUseCase(repository: todoRepository),
            loadAllTodosUseCase: DefaultLoadAllTodosUseCase(repository: todoRepository),
            holidayUseCase: holidayUseCase
        )

        // ✅ 루트 뷰컨트롤러 주입
        let rootViewController = CalendarViewController(
            viewModel: viewModel,
            holidayUseCase: holidayUseCase
        )

        // ✅ 윈도우 설정
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }
}
