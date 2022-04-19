//
//  TaskTableViewCellViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

import RxDataSources

class TaskTableViewCellViewModel {
    private  let _id = UUID().uuidString
    private let _task: Task
    private let _isNewTask: Bool

    init(task: Task, isNewTask: Bool = false) {
        _task = task
        _isNewTask = isNewTask
    }

    public var getId: String {
        _id
    }

    public var task: Task {
        _task
    }

    public var text: String {
        _task.getText
    }

    public var isChecked: Bool {
        _task.getIsChecked
    }

    public var isNewTask: Bool {
        _isNewTask
    }
}

extension TaskTableViewCellViewModel: IdentifiableType, Equatable {
    var identity: String {
        return self._id
    }

    static func == (lhs: TaskTableViewCellViewModel, rhs: TaskTableViewCellViewModel) -> Bool {
        return lhs.identity == rhs.identity
    }
}
