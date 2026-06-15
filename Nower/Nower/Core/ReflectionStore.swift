//
//  ReflectionStore.swift
//  Nower (macOS)
//
//  하루 체감 기록(DayReflection) 영속 계층.
//  NowerCore StorageProvider 위에 얹어 날짜별 1건(upsert)으로 관리한다.
//  iCloud KV 저장 — 사용자 본인 계정 안에만 머문다(제3자 미전송, 온디바이스 원칙).
//

import Foundation

#if canImport(NowerCore)
import NowerCore

@MainActor
final class ReflectionStore {

    private let storage: StorageProvider

    init(storage: StorageProvider) {
        self.storage = storage
    }

    /// 전체 체감 기록 (날짜 오름차순)
    func all() -> [DayReflection] {
        if case .success(let value) = storage.load(forKey: StorageKeys.dayReflections) as Result<[DayReflection]?, NowerError>,
           let list = value {
            return list.sorted { $0.date < $1.date }
        }
        return []
    }

    /// 특정 날짜의 기록 (없으면 nil)
    func reflection(for date: Date) -> DayReflection? {
        let key = DayReflection.dateKey(date)
        return all().first { DayReflection.dateKey($0.date) == key }
    }

    /// 날짜별 1건으로 저장(같은 날 기록은 덮어씀)
    @discardableResult
    func upsert(_ reflection: DayReflection) -> Bool {
        let key = DayReflection.dateKey(reflection.date)
        var list = all().filter { DayReflection.dateKey($0.date) != key }
        list.append(reflection)
        list.sort { $0.date < $1.date }
        if case .success = storage.save(list, forKey: StorageKeys.dayReflections) {
            storage.synchronize()
            return true
        }
        return false
    }

    /// 특정 날짜 기록 삭제
    func remove(for date: Date) {
        let key = DayReflection.dateKey(date)
        let list = all().filter { DayReflection.dateKey($0.date) != key }
        _ = storage.save(list, forKey: StorageKeys.dayReflections)
        storage.synchronize()
    }
}

#endif
