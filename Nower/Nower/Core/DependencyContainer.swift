//
//  DependencyContainer.swift
//  Nower (macOS)
//
//  NowerCore 의존성 관리 컨테이너
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

#if canImport(NowerCore)
import NowerCore

/// NowerCore 의존성 관리 컨테이너
/// 앱 전체에서 사용하는 모든 NowerCore 관련 의존성을 관리합니다.
@MainActor
public final class DependencyContainer {
    // MARK: - Singleton

    public static let shared = DependencyContainer()

    // MARK: - Storage

    /// 기본 저장소 (iCloud)
    public lazy var storageProvider: StorageProvider = iCloudStorageProvider()

    // MARK: - Repositories

    /// 이벤트 저장소
    public lazy var eventRepository: NowerCore.EventRepository = EventRepositoryImpl(storage: storageProvider)

    /// 템플릿 저장소
    public lazy var templateRepository: NowerCore.TemplateRepository = TemplateRepositoryImpl(storage: storageProvider)

    // MARK: - Migration

    /// 마이그레이션 관리자
    public lazy var migrationManager: MigrationManager = MigrationManager(storage: storageProvider)

    // MARK: - Sync

    /// 동기화 관리자
    public lazy var syncManager: SyncManager = iCloudSyncManager(storage: storageProvider, eventRepository: eventRepository)

    /// 동기화 상태 옵저버
    public lazy var syncStateObserver: SyncStateObserving = DefaultSyncStateObserver(
        syncManager: syncManager,
        dataSource: CloudSyncManager.shared
    )

    // MARK: - Use Cases (NowerCore)

    public lazy var addEventUseCase: NowerCore.AddEventUseCase = DefaultAddEventUseCase(repository: eventRepository)
    public lazy var deleteEventUseCase: NowerCore.DeleteEventUseCase = DefaultDeleteEventUseCase(repository: eventRepository)
    public lazy var updateEventUseCase: NowerCore.UpdateEventUseCase = DefaultUpdateEventUseCase(repository: eventRepository)
    public lazy var fetchEventsUseCase: NowerCore.FetchEventsUseCase = DefaultFetchEventsUseCase(repository: eventRepository)
    public lazy var moveEventUseCase: NowerCore.MoveEventUseCase = DefaultMoveEventUseCase(repository: eventRepository)
    public lazy var fetchTemplatesUseCase: NowerCore.FetchTemplatesUseCase = DefaultFetchTemplatesUseCase(repository: templateRepository)
    public lazy var saveTemplateUseCase: NowerCore.SaveTemplateUseCase = DefaultSaveTemplateUseCase(repository: templateRepository)
    public lazy var deleteTemplateUseCase: NowerCore.DeleteTemplateUseCase = DefaultDeleteTemplateUseCase(repository: templateRepository)

    // MARK: - Initialization

    private init() {}

    // MARK: - Migration

    /// 앱 시작 시 마이그레이션 수행
    /// - Returns: 마이그레이션 성공 여부
    @discardableResult
    public func runMigrationIfNeeded() -> Bool {
        if migrationManager.needsMigration {
            print("🔄 [DependencyContainer] 데이터 마이그레이션 시작...")

            let result = migrationManager.migrateIfNeeded()

            switch result {
            case .success:
                print("✅ [DependencyContainer] 마이그레이션 완료")
                return true
            case .failure(let error):
                print("❌ [DependencyContainer] 마이그레이션 실패: \(error.localizedDescription)")
                return false
            }
        }

        print("ℹ️ [DependencyContainer] 마이그레이션 필요 없음 (현재 버전: \(storageProvider.schemaVersion))")
        return true
    }

    /// 동기화 리스너 시작
    public func startSyncListening() {
        syncManager.startListening()
        print("🔄 [DependencyContainer] iCloud 동기화 리스너 시작")
    }

    /// 동기화 리스너 중지
    public func stopSyncListening() {
        syncManager.stopListening()
    }
}

// MARK: - Legacy Support Factory

extension DependencyContainer {
    /// 레거시 TodoRepository 생성 (기존 코드와의 호환성 유지)
    /// 점진적 마이그레이션을 위해 기존 인터페이스를 유지합니다.
    func makeLegacyTodoRepository() -> TodoRepository {
        return TodoRepositoryImpl()
    }

    /// 레거시 UseCase 생성 (기존 코드와의 호환성 유지)
    func makeLegacyUseCases() -> (
        add: AddTodoUseCase,
        delete: DeleteTodoUseCase,
        update: UpdateTodoUseCase,
        getByDate: GetTodosByDateUseCase,
        loadAll: LoadAllTodosUseCase,
        move: MoveTodoUseCase
    ) {
        let repository = makeLegacyTodoRepository()
        return (
            add: DefaultAddTodoUseCase(repository: repository),
            delete: DefaultDeleteTodoUseCase(repository: repository),
            update: DefaultUpdateTodoUseCase(repository: repository),
            getByDate: DefaultGetTodosByDateUseCase(repository: repository),
            loadAll: DefaultLoadAllTodosUseCase(repository: repository),
            move: DefaultMoveTodoUseCase(repository: repository)
        )
    }
}

#else

// MARK: - Stub when NowerCore is not available

/// NowerCore 패키지가 연결되지 않았을 때의 플레이스홀더
@MainActor
public final class DependencyContainer {
    public static let shared = DependencyContainer()
    private init() {}

    @discardableResult
    public func runMigrationIfNeeded() -> Bool {
        print("⚠️ NowerCore 패키지가 연결되지 않았습니다.")
        return true
    }

    public func startSyncListening() {
        print("⚠️ NowerCore 패키지가 연결되지 않았습니다.")
    }

    public func stopSyncListening() {}
}

#endif
