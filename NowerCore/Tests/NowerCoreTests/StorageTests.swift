//
//  StorageTests.swift
//  NowerCoreTests
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import XCTest
@testable import NowerCore

final class StorageTests: XCTestCase {

    var storage: InMemoryStorageProvider!

    override func setUp() {
        super.setUp()
        storage = InMemoryStorageProvider()
    }

    override func tearDown() {
        storage.removeAll()
        storage = nil
        super.tearDown()
    }

    // MARK: - Basic Operations

    func testSaveAndLoad() {
        let testValue = "Hello, World!"

        let saveResult = storage.save(testValue, forKey: "test")
        XCTAssertTrue(saveResult.isSuccess)

        let loadResult: Result<String?, NowerError> = storage.load(forKey: "test")
        XCTAssertEqual(loadResult.successValue, testValue)
    }

    func testSaveAndLoadCodable() {
        let event = Event.allDay(title: "테스트", date: Date())

        let saveResult = storage.save(event, forKey: "event")
        XCTAssertTrue(saveResult.isSuccess)

        let loadResult: Result<Event?, NowerError> = storage.load(forKey: "event")
        XCTAssertNotNil(loadResult.successValue)
        XCTAssertEqual(loadResult.successValue??.id, event.id)
    }

    func testSaveAndLoadArray() {
        let events = [
            Event.allDay(title: "일정1", date: Date()),
            Event.allDay(title: "일정2", date: Date()),
        ]

        let saveResult = storage.save(events, forKey: StorageKeys.events)
        XCTAssertTrue(saveResult.isSuccess)

        let loadResult: Result<[Event]?, NowerError> = storage.load(forKey: StorageKeys.events)
        XCTAssertEqual(loadResult.successValue??.count, 2)
    }

    // MARK: - Exists

    func testExists() {
        XCTAssertFalse(storage.exists(forKey: "nonexistent"))

        _ = storage.save("value", forKey: "exists")
        XCTAssertTrue(storage.exists(forKey: "exists"))
    }

    // MARK: - Remove

    func testRemove() {
        _ = storage.save("value", forKey: "toRemove")
        XCTAssertTrue(storage.exists(forKey: "toRemove"))

        storage.remove(forKey: "toRemove")
        XCTAssertFalse(storage.exists(forKey: "toRemove"))
    }

    func testRemoveAll() {
        _ = storage.save("value1", forKey: "key1")
        _ = storage.save("value2", forKey: "key2")
        _ = storage.save("value3", forKey: "key3")

        storage.removeAll()

        XCTAssertFalse(storage.exists(forKey: "key1"))
        XCTAssertFalse(storage.exists(forKey: "key2"))
        XCTAssertFalse(storage.exists(forKey: "key3"))
    }

    // MARK: - Schema Version

    func testSchemaVersion() {
        XCTAssertEqual(storage.schemaVersion, 1) // 기본값

        storage.schemaVersion = 5
        XCTAssertEqual(storage.schemaVersion, 5)
    }

    // MARK: - Thread Safety (Concurrent Access)

    func testConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent writes complete")
        let iterations = 100

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let value = "Value \(i)"
            _ = storage.save(value, forKey: "concurrent_\(i)")
        }

        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)

        // 모든 값이 저장되었는지 확인
        for i in 0..<iterations {
            XCTAssertTrue(storage.exists(forKey: "concurrent_\(i)"))
        }
    }
}
