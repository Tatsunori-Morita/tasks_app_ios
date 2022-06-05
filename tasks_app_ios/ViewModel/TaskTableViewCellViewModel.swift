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

    public var id: String {
        _task.id
    }

    public var task: Task {
        _task
    }

    public var title: String {
        _task.title
    }

    public var notes: String {
        _task.notes
    }

    public var isChecked: Bool {
        _task.isChecked
    }

    public var isNewTask: Bool {
        _isNewTask
    }

    public var parentId: String {
        _task.parentId
    }

    public var subTasks: [Task] {
        _task.subTasks
    }

    public var isChild: Bool {
        !_task.parentId.isEmpty
    }
}

extension TaskTableViewCellViewModel: IdentifiableType, Equatable {
    public var identity: String {
        return self._task.id
    }

    static func == (lhs: TaskTableViewCellViewModel, rhs: TaskTableViewCellViewModel) -> Bool {
        return lhs.identity == rhs.identity
    }
}
