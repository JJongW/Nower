//
//  TemplateTests.swift
//  NowerCoreTests
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import XCTest
@testable import NowerCore

final class TemplateTests: XCTestCase {

    var storage: InMemoryStorageProvider!
    var repository: TemplateRepositoryImpl!
    var saveUseCase: DefaultSaveTemplateUseCase!
    var deleteUseCase: DefaultDeleteTemplateUseCase!
    var fetchUseCase: DefaultFetchTemplatesUseCase!

    override func setUp() {
        super.setUp()
        storage = InMemoryStorageProvider()
        repository = TemplateRepositoryImpl(storage: storage)
        saveUseCase = DefaultSaveTemplateUseCase(repository: repository)
        deleteUseCase = DefaultDeleteTemplateUseCase(repository: repository)
        fetchUseCase = DefaultFetchTemplatesUseCase(repository: repository)
    }

    override func tearDown() {
        storage.removeAll()
        storage = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Save & FetchAll

    func testSaveAndFetchAll() {
        let template = EventTemplate(name: "치과", title: "치과 예약", colorName: "skyblue-4")
        let saveResult = saveUseCase.execute(template)
        XCTAssertTrue(saveResult.isSuccess)

        let fetchResult = fetchUseCase.executeAll()
        guard case .success(let all) = fetchResult else {
            XCTFail("fetchAll failed")
            return
        }
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "치과")
        XCTAssertEqual(all.first?.title, "치과 예약")
    }

    // MARK: - fetch(matchingPrefix:)

    func testFetchMatchingPrefix() {
        let t1 = EventTemplate(name: "치과 예약", title: "치과 정기검진", colorName: "peach-4")
        let t2 = EventTemplate(name: "팀 미팅", title: "팀 주간 미팅", colorName: "skyblue-4")
        let t3 = EventTemplate(name: "치과 x-ray", title: "치과 엑스레이", colorName: "lavender-4")

        _ = saveUseCase.execute(t1)
        _ = saveUseCase.execute(t2)
        _ = saveUseCase.execute(t3)

        let result = fetchUseCase.execute(matchingPrefix: "치")
        guard case .success(let found) = result else {
            XCTFail("fetch(matchingPrefix:) failed")
            return
        }
        XCTAssertEqual(found.count, 2)
        XCTAssertTrue(found.allSatisfy { $0.name.hasPrefix("치") })
    }

    func testFetchMatchingPrefixCaseInsensitive() {
        let template = EventTemplate(name: "Meeting", title: "Weekly Meeting", colorName: "skyblue-4")
        _ = saveUseCase.execute(template)

        let result = fetchUseCase.execute(matchingPrefix: "meet")
        guard case .success(let found) = result else {
            XCTFail("fetch(matchingPrefix:) failed")
            return
        }
        XCTAssertEqual(found.count, 1)
    }

    func testFetchMatchingPrefixEmpty() {
        let template = EventTemplate(name: "치과", title: "치과 예약", colorName: "skyblue-4")
        _ = saveUseCase.execute(template)

        let result = fetchUseCase.execute(matchingPrefix: "")
        guard case .success(let found) = result else {
            XCTFail("fetch(matchingPrefix:) failed")
            return
        }
        XCTAssertEqual(found.count, 0, "빈 prefix는 결과 없음")
    }

    // MARK: - Delete

    func testDeleteRemovesTemplate() {
        let template = EventTemplate(name: "치과", title: "치과 예약", colorName: "skyblue-4")
        _ = saveUseCase.execute(template)

        let deleteResult = deleteUseCase.execute(template)
        XCTAssertTrue(deleteResult.isSuccess)

        let fetchResult = fetchUseCase.executeAll()
        guard case .success(let all) = fetchResult else {
            XCTFail("fetchAll after delete failed")
            return
        }
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - Validation

    func testSaveWithEmptyNameFails() {
        let template = EventTemplate(name: "", title: "치과 예약", colorName: "skyblue-4")
        let result = saveUseCase.execute(template)
        XCTAssertTrue(result.isFailure)
    }

    func testSaveWithEmptyTitleFails() {
        let template = EventTemplate(name: "치과", title: "", colorName: "skyblue-4")
        let result = saveUseCase.execute(template)
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - RecurrenceRule

    func testSaveTemplateWithRecurrence() {
        let rule = RecurrenceRule(frequency: .weekly)
        let template = EventTemplate(name: "팀 미팅", title: "팀 주간 회의", colorName: "skyblue-4", recurrenceRule: rule)
        _ = saveUseCase.execute(template)

        let result = fetchUseCase.executeAll()
        guard case .success(let all) = result, let first = all.first else {
            XCTFail("fetchAll failed")
            return
        }
        XCTAssertNotNil(first.recurrenceRule)
        XCTAssertEqual(first.recurrenceRule?.frequency, .weekly)
    }
}
