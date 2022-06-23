//
//  tasks_app_iosTests.swift
//  tasks_app_iosTests
//
//  Created by Tatsunori on 2022/06/23.
//

import XCTest

class tasks_app_iosTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let ans = DataSource.shared.testMethod()
        XCTAssertEqual(ans, 1)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
