//
//  tasks_app_iosTests.swift
//  tasks_app_iosTests
//
//  Created by Tatsunori on 2022/06/23.
//

import XCTest

class tasks_app_iosTests: XCTestCase {
    let _dataSource = DataSource.shared

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testChangeCheckMark() throws {
        let parentId = UUID().uuidString
        let isChecked = true

        let parentTask = Task(id: parentId, title: "parent task", notes: "", isChecked: isChecked, subTasks: [], isShowedSubTask: true)
        _dataSource.addTask(task: parentTask)

        let subTask1 = Task(id: UUID().uuidString, title: "sub task1", notes: "", isChecked: isChecked, parentId: parentId)
        _dataSource.addTask(task: subTask1)

        let subTask2 = Task(id: UUID().uuidString, title: "sub task2", notes: "", isChecked: isChecked, parentId: parentId)
        _dataSource.addTask(task: subTask2)

        _dataSource.log()
        
        let newParentTask = parentTask.changeValue(isChecked: !parentTask.isChecked)
        let newParentTaskViewModel = TaskTableViewCellViewModel(task: newParentTask)
        _dataSource.changeCheckMark(viewModel: newParentTaskViewModel, beforeId: parentId)

        _dataSource.log()

        let afterChangedSubTasks = _dataSource.getOpenedSubTasks(parentId: parentId)
        afterChangedSubTasks.forEach { task in
            XCTAssertEqual(task.isChecked, !isChecked)
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
