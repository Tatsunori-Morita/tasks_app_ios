//
//  TaskTableViewCellViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

import RxDataSources

class TaskTableViewCellViewModel {
    private let _id: String
    private let _task: Task
    private let _isNewTask: Bool
    private let _hasSubTasks: Bool

    init(id: String = UUID().uuidString, task: Task, isNewTask: Bool = false, hasSubTasks: Bool = false) {
        _id = id
        _task = task
        _isNewTask = isNewTask
        _hasSubTasks = hasSubTasks
    }

    public var taskId: String {
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

    public var isShowedSubTasks: Bool {
        _task.isShowedSubTask
    }

    public var hasSubTasks: Bool {
        _hasSubTasks || task.subTasks.count > 0
    }

    public func changeValues(hasSubTasks: Bool) -> TaskTableViewCellViewModel {
        return TaskTableViewCellViewModel(id: _id, task: task, isNewTask: _isNewTask, hasSubTasks: hasSubTasks)
    }
}

extension TaskTableViewCellViewModel: IdentifiableType, Equatable {
    public var identity: String {
        return _id
    }

    static func == (lhs: TaskTableViewCellViewModel, rhs: TaskTableViewCellViewModel) -> Bool {
        return lhs.identity == rhs.identity
    }
}
