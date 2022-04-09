//
//  TaskTableViewCellViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

import RxDataSources

class TaskTableViewCellViewModel: Codable {
    private var _text: String
    private var _isChecked: Bool
    private var _isNewTask: Bool

    init(text: String, isChecked: Bool, isNewTask: Bool = false) {
        self._text = text
        self._isChecked = isChecked
        self._isNewTask = isNewTask
    }

    public var text: String {
        _text
    }

    public var isChecked: Bool {
        _isChecked
    }

    public var isNewTask: Bool {
        _isNewTask
    }
}

extension TaskTableViewCellViewModel: IdentifiableType, Equatable {
    var identity: String {
        return self.text
    }

    static func == (lhs: TaskTableViewCellViewModel, rhs: TaskTableViewCellViewModel) -> Bool {
        return lhs.text == rhs.text && lhs.isChecked == rhs.isChecked && lhs.isNewTask == rhs.isNewTask
    }
}

struct TaskTableViewSectionViewModel: Codable {
    var header: String
    var items: [Item]
}

extension TaskTableViewSectionViewModel: AnimatableSectionModelType {
    typealias Item = TaskTableViewCellViewModel

    var identity: String {
        return header
    }

    init(original: TaskTableViewSectionViewModel, items: [Item]) {
        self = original
        self.items = items
    }
}
