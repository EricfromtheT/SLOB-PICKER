//
//  SlobPickerTests.swift
//  SlobPickerTests
//
//  Created by 孔令傑 on 2022/12/8.
//

import XCTest
@testable import SlobPicker

final class SlobPickerTests: XCTestCase {
    var sut: PickResultViewController!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = PickResultViewController()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testPickerResult() throws {
        sut.mode = .forPublic
        let uselessString = ""
        sut.pickInfo = Picker(title: uselessString, description: uselessString, type: 0, contents: ["", "", "", ""], authorID: uselessString, authorName: uselessString, authorUUID: uselessString)
        let pickResults = [PickResult(choice: 0, createdTime: 43143, userUUID: "fjiejaf;aef"),
                           PickResult(choice: 3, createdTime: 89431, userUUID: "fealhgjra"),
                           PickResult(choice: 2, createdTime: 54351, userUUID: "fdagerag"),
                           PickResult(choice: 1, createdTime: 45151, userUUID: "fjrkljagra"),
                           PickResult(choice: 1, createdTime: 415541, userUUID: "fekajgkr;ag"),
                           PickResult(choice: 2, createdTime: 451541, userUUID: "lhgrhalgrol")
        ]
        sut.organizeResult(data: pickResults)
        XCTAssertEqual(sut.voteResults[0].votes, 2, "count is not good")
    }
    
    func testPickerEmptyResult() throws {
        sut.mode = .forPublic
        sut.pickInfo = Picker(title: "fdsafea", description: "feaf", type: 0, contents: ["", "", "", ""], authorID: "feafe", authorName: "fragr", authorUUID: "feagrar")
        let pickResults:[PickResult] = []
        sut.organizeResult(data: pickResults)
        XCTAssertEqual(sut.voteResults[0].votes, 0, "count is not good")
    }
}
