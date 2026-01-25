//
//  StorageProvider.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 저장소 키 상수
public enum StorageKeys {
    public static let events = "Events"
    public static let legacyTodos = "SavedTodos"
    public static let legacyBackup = "SavedTodos_backup_v1"
    public static let schemaVersion = "SchemaVersion"
    public static let lastSyncDate = "LastSyncDate"
    public static let userPreferences = "UserPreferences"
}

/// 저장소 제공자 프로토콜
/// 데이터 저장 및 로드를 추상화하여 다양한 저장소 구현을 지원합니다.
public protocol StorageProvider: Sendable {
    /// 데이터 저장
    /// - Parameters:
    ///   - value: 저장할 값 (Codable)
    ///   - key: 저장소 키
    /// - Returns: 성공 또는 에러
    func save<T: Codable>(_ value: T, forKey key: String) -> Result<Void, NowerError>

    /// 데이터 로드
    /// - Parameter key: 저장소 키
    /// - Returns: 로드된 값 또는 에러
    func load<T: Codable>(forKey key: String) -> Result<T?, NowerError>

    /// 키 존재 여부 확인
    /// - Parameter key: 확인할 키
    /// - Returns: 존재 여부
    func exists(forKey key: String) -> Bool

    /// 데이터 삭제
    /// - Parameter key: 삭제할 키
    func remove(forKey key: String)

    /// 모든 데이터 삭제
    func removeAll()

    /// 동기화 강제 실행
    func synchronize()

    /// 스키마 버전
    var schemaVersion: Int { get set }

    /// 저장소 사용 가능 여부
    var isAvailable: Bool { get }
}

// MARK: - Default Implementations

public extension StorageProvider {
    /// 스키마 버전 기본 구현
    var schemaVersion: Int {
        get {
            if case .success(let version) = load(forKey: StorageKeys.schemaVersion) as Result<Int?, NowerError>,
               let v = version {
                return v
            }
            return 1 // 기본 버전
        }
        set {
            _ = save(newValue, forKey: StorageKeys.schemaVersion)
        }
    }
}

// MARK: - iCloud Storage Provider

#if canImport(Foundation)
/// iCloud 기반 저장소 제공자
public final class iCloudStorageProvider: StorageProvider, @unchecked Sendable {
    private let store: NSUbiquitousKeyValueStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue: DispatchQueue

    public init(store: NSUbiquitousKeyValueStore = .default) {
        self.store = store
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.queue = DispatchQueue(label: "com.nower.storage", qos: .userInitiated)
    }

    public var isAvailable: Bool {
        // iCloud 가용성 확인
        return FileManager.default.ubiquityIdentityToken != nil
    }

    public func save<T: Codable>(_ value: T, forKey key: String) -> Result<Void, NowerError> {
        do {
            let data = try encoder.encode(value)
            queue.sync {
                store.set(data, forKey: key)
            }
            return .success(())
        } catch {
            return .failure(.encodingFailed)
        }
    }

    public func load<T: Codable>(forKey key: String) -> Result<T?, NowerError> {
        return queue.sync {
            guard let data = store.data(forKey: key) else {
                return .success(nil)
            }

            do {
                let value = try decoder.decode(T.self, from: data)
                return .success(value)
            } catch {
                return .failure(.decodingFailed)
            }
        }
    }

    public func exists(forKey key: String) -> Bool {
        queue.sync {
            store.object(forKey: key) != nil
        }
    }

    public func remove(forKey key: String) {
        queue.sync {
            store.removeObject(forKey: key)
        }
    }

    public func removeAll() {
        queue.sync {
            for key in store.dictionaryRepresentation.keys {
                store.removeObject(forKey: key)
            }
        }
    }

    public func synchronize() {
        _ = queue.sync {
            store.synchronize()
        }
    }

    public var schemaVersion: Int {
        get {
            queue.sync {
                Int(store.longLong(forKey: StorageKeys.schemaVersion))
            }
        }
        set {
            queue.sync {
                store.set(Int64(newValue), forKey: StorageKeys.schemaVersion)
            }
        }
    }
}
#endif

// MARK: - Local Storage Provider

/// 로컬 UserDefaults 기반 저장소 제공자 (오프라인 또는 테스트용)
public final class LocalStorageProvider: StorageProvider, @unchecked Sendable {
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue: DispatchQueue
    private let keyPrefix: String

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "com.nower.local."
    ) {
        self.defaults = defaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.queue = DispatchQueue(label: "com.nower.localStorage", qos: .userInitiated)
        self.keyPrefix = keyPrefix
    }

    public var isAvailable: Bool { true }

    private func prefixedKey(_ key: String) -> String {
        keyPrefix + key
    }

    public func save<T: Codable>(_ value: T, forKey key: String) -> Result<Void, NowerError> {
        do {
            let data = try encoder.encode(value)
            queue.sync {
                defaults.set(data, forKey: prefixedKey(key))
            }
            return .success(())
        } catch {
            return .failure(.encodingFailed)
        }
    }

    public func load<T: Codable>(forKey key: String) -> Result<T?, NowerError> {
        return queue.sync {
            guard let data = defaults.data(forKey: prefixedKey(key)) else {
                return .success(nil)
            }

            do {
                let value = try decoder.decode(T.self, from: data)
                return .success(value)
            } catch {
                return .failure(.decodingFailed)
            }
        }
    }

    public func exists(forKey key: String) -> Bool {
        queue.sync {
            defaults.object(forKey: prefixedKey(key)) != nil
        }
    }

    public func remove(forKey key: String) {
        queue.sync {
            defaults.removeObject(forKey: prefixedKey(key))
        }
    }

    public func removeAll() {
        queue.sync {
            let allKeys = defaults.dictionaryRepresentation().keys
            for key in allKeys where key.hasPrefix(keyPrefix) {
                defaults.removeObject(forKey: key)
            }
        }
    }

    public func synchronize() {
        _ = queue.sync {
            defaults.synchronize()
        }
    }

    public var schemaVersion: Int {
        get {
            queue.sync {
                defaults.integer(forKey: prefixedKey(StorageKeys.schemaVersion))
            }
        }
        set {
            queue.sync {
                defaults.set(newValue, forKey: prefixedKey(StorageKeys.schemaVersion))
            }
        }
    }
}

// MARK: - In-Memory Storage Provider (테스트용)

/// 메모리 기반 저장소 제공자 (테스트용)
public final class InMemoryStorageProvider: StorageProvider, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let queue: DispatchQueue
    private var _schemaVersion: Int = 1

    public init() {
        self.queue = DispatchQueue(label: "com.nower.memoryStorage", qos: .userInitiated)
    }

    public var isAvailable: Bool { true }

    public func save<T: Codable>(_ value: T, forKey key: String) -> Result<Void, NowerError> {
        do {
            let data = try JSONEncoder().encode(value)
            queue.sync {
                storage[key] = data
            }
            return .success(())
        } catch {
            return .failure(.encodingFailed)
        }
    }

    public func load<T: Codable>(forKey key: String) -> Result<T?, NowerError> {
        return queue.sync {
            guard let data = storage[key] else {
                return .success(nil)
            }

            do {
                let value = try JSONDecoder().decode(T.self, from: data)
                return .success(value)
            } catch {
                return .failure(.decodingFailed)
            }
        }
    }

    public func exists(forKey key: String) -> Bool {
        queue.sync { storage[key] != nil }
    }

    public func remove(forKey key: String) {
        queue.sync { storage[key] = nil }
    }

    public func removeAll() {
        queue.sync { storage.removeAll() }
    }

    public func synchronize() {
        // 메모리 저장소는 동기화 불필요
    }

    public var schemaVersion: Int {
        get { queue.sync { _schemaVersion } }
        set { queue.sync { _schemaVersion = newValue } }
    }
}
