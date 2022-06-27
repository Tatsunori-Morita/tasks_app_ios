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

    override func setUp() {
        _dataSource.clearUserDefaults()
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
        _dataSource.changeCheckMark(viewModel: newParentTaskViewModel)

        _dataSource.log()

        let afterChangedSubTasks = _dataSource.getOpenedSubTasks(parentId: parentId)
        afterChangedSubTasks.forEach { task in
            XCTAssertEqual(task.isChecked, !isChecked)
        }
    }

    func testRemoveParentTask() throws {
        let parentId = UUID().uuidString
        let parentTask = Task(id: parentId, title: "remove parent", notes: "", isChecked: false, subTasks: [], isShowedSubTask: true)
        _dataSource.addTask(task: parentTask)

        let subTask1 = Task(id: UUID().uuidString, title: "remove subTask1", notes: "", isChecked: false, parentId: parentId,subTasks: [], isShowedSubTask: false)
        _dataSource.addTask(task: subTask1)

        let subTask2 = Task(id: UUID().uuidString, title: "remove subTask2", notes: "", isChecked: false, parentId: parentId,subTasks: [], isShowedSubTask: false)
        _dataSource.addTask(task: subTask2)

        let parentTaskViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: parentId)

        let subTask1ViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: subTask1.id)
        let subTask2ViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: subTask2.id)

        _dataSource.removeTask(viewModel: subTask1ViewModel)

        if _dataSource.hasTaskId(taskId: subTask1ViewModel.taskId) {
            XCTFail()
        }

        _dataSource.removeTask(viewModel: parentTaskViewModel)

        if _dataSource.hasTaskId(taskId: subTask2ViewModel.taskId) {
            XCTFail()
        }

        if _dataSource.hasTaskId(taskId: parentTaskViewModel.taskId) {
            XCTFail()
        }

        _dataSource.log()
    }

    func testRemoveAllSubTasks() throws {
        let parentId = UUID().uuidString
        let parentTask = Task(id: parentId, title: "remove parent", notes: "", isChecked: false, subTasks: [], isShowedSubTask: true)
        _dataSource.addTask(task: parentTask)

        let subTask1 = Task(id: UUID().uuidString, title: "remove subTask1", notes: "", isChecked: false, parentId: parentId,subTasks: [], isShowedSubTask: false)
        _dataSource.addTask(task: subTask1)

        let subTask2 = Task(id: UUID().uuidString, title: "remove subTask2", notes: "", isChecked: false, parentId: parentId,subTasks: [], isShowedSubTask: false)
        _dataSource.addTask(task: subTask2)

        let parentTaskViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: parentId)
        let subTask1ViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: subTask1.id)
        let subTask2ViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: subTask2.id)

        _dataSource.removeTask(viewModel: subTask1ViewModel)
        _dataSource.removeTask(viewModel: subTask2ViewModel)

        _dataSource.log()

        let newParentTaskViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: parentId)

        XCTAssertNotEqual(parentTaskViewModel.identity, newParentTaskViewModel.identity)
        XCTAssertEqual(newParentTaskViewModel.isShowedSubTasks, false)
    }

    func testChangeTitle() throws {
        let parentId = UUID().uuidString
        let parentTask = Task(id: parentId, title: "parent task title", notes: "", isChecked: false, subTasks: [], isShowedSubTask: true)
        _dataSource.addTask(task: parentTask)

        let subTaskId = UUID().uuidString
        let subTask = Task(id: subTaskId, title: "sub task title", notes: "", isChecked: false, parentId: parentId, subTasks: [], isShowedSubTask: false)
        _dataSource.addTask(task: subTask)

        let oldParentTaskViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: parentId)
        let newTask = oldParentTaskViewModel.task.changeValue(title: "new parent task title")
        let newParentTaskViewModel = TaskTableViewCellViewModel(task: newTask)
        _dataSource.changeTitle(viewModel: newParentTaskViewModel)

        print("-------- Change Parent task title -----------")
        _dataSource.log()

        let changedAfterParentViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: parentId)

        if changedAfterParentViewModel.title != newParentTaskViewModel.title {
            XCTFail("titleの変更が正しくおこなわれませんでした。")
        }

        // remove sub task.
        let oldSubTaskViewModel = _dataSource.getTaskTableViewCellViewModel(taskId: subTaskId)
        let newSubTask = oldSubTaskViewModel.task.changeValue(title: "")
        let newSubTaskViewModel = TaskTableViewCellViewModel(task: newSubTask)
        _dataSource.changeTitle(viewModel: newSubTaskViewModel)

        print("-------- Remove Sub task -----------")
        _dataSource.log()

        let changedAfterParentViewModelNotHasSubTask = _dataSource.getTaskTableViewCellViewModel(taskId: parentId)

        if !changedAfterParentViewModelNotHasSubTask.subTasks.isEmpty || changedAfterParentViewModelNotHasSubTask.isShowedSubTasks {
            XCTFail("Parent taskの値が正しくありません。")
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
