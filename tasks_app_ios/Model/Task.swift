//
//  Task.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/14.
//

import Foundation

class Task: Codable {
    private let _id: String
    private let _title: String
    private let _notes: String
    private let _isChecked: Bool
    private let _parentId: String
    private let _subTasks: [Task]
    private let _hasSubTasks: Bool
    private let _isShowedSubTask: Bool

    init(id: String, title: String, notes: String, isChecked: Bool,
         parentId: String = "", subTasks: [Task] = [], hasSubTasks: Bool, isShowedSubTask: Bool = false) {
        _id = id
        _title = title
        _notes = notes
        _isChecked = isChecked
        _parentId = parentId
        _subTasks = subTasks
        _hasSubTasks = hasSubTasks
        _isShowedSubTask = isShowedSubTask
    }

    public var id: String {
        _id
    }

    public var title: String {
        _title
    }

    public var notes: String {
        _notes
    }

    public var isChecked: Bool {
        _isChecked
    }

    public var parentId: String {
        _parentId
    }

    public var subTasks: [Task] {
        _subTasks
    }

    public var hasSubTasks: Bool {
        _hasSubTasks
    }

    public var isShowedSubTask: Bool {
        _isShowedSubTask
    }

    public func changeValues(
        title: String, notes: String, isChecked: Bool, isShowedSubTasks: Bool,
        hasSubTasks: Bool, subTasks: [Task] = []) -> Task {
            let oldSubTasks = isShowedSubTasks ? subTasks : (hasSubTasks && !subTasks.isEmpty) ? subTasks : _subTasks
        let newSubTasks = oldSubTasks.map { task in
            return Task(id: task.id, title: task.title, notes: task.notes,
                        isChecked: task.isChecked, parentId: task.parentId,
                        subTasks: task.subTasks, hasSubTasks: task.hasSubTasks,
                        isShowedSubTask: task.isShowedSubTask)
        }
        return Task(id: _id, title: title, notes: notes,
                    isChecked: isChecked, parentId: _parentId,
                    subTasks: newSubTasks, hasSubTasks: hasSubTasks,
                    isShowedSubTask: isShowedSubTasks)
    }

    public func toString() {
        print("----------------------- Parent Task ----------------------------")
        print("id:\(_id) title:\(_title) notes:\(_notes) isChecked:\(_isChecked) parentId:\(_parentId) isShowedSubTask:\(_isShowedSubTask)")
        print("----------------------- Sub Task ----------------------------")
        _subTasks.forEach { task in
            print("id:\(task.id) title:\(task.title) notes:\(task.notes) isChecked:\(task.isChecked) parentId:\(task.parentId) isShowedSubTask:\(task.isShowedSubTask)")
        }
        print("-------------------------------------------------------------")
    }
}
