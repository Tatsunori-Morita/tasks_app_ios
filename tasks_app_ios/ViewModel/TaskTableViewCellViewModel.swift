//
//  TaskTableViewCellViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

import RxDataSources

class TaskTableViewCellViewModel {
    private let _task: Task
    private let _isNewTask: Bool

    init(task: Task, isNewTask: Bool = false) {
        _task = task
        _isNewTask = isNewTask
    }

    public var getId: String {
        _task.getId
    }

    public var task: Task {
        _task
    }

    public var text: String {
        _task.getTitle
    }

    public var isChecked: Bool {
        _task.getIsChecked
    }

    public var isNewTask: Bool {
        _isNewTask
    }

    public var parentId: String {
        _task.getParentId
    }
}

extension TaskTableViewCellViewModel: IdentifiableType, Equatable {
    public var identity: String {
        return self._task.getId
    }

    static func == (lhs: TaskTableViewCellViewModel, rhs: TaskTableViewCellViewModel) -> Bool {
        return lhs.identity == rhs.identity
    }
}
