//
//  DetailViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/05/27.
//

import RxSwift
import RxCocoa
import RxDataSources

class DetailViewModel: BaseViewModel {
    private let _task: Task
    private let _isNewTask: Bool

    init(task: Task, isNewTask: Bool = false, parentId: String = "") {
        _task = task
        _isNewTask = isNewTask
        super.init()
        _dataSource.loadSubTasks(parentId: parentId)
    }

    public var task: Task {
        _task
    }

    public var id: String {
        _task.getId
    }

    public var text: String {
        _task.getTitle
    }

    public var notes: String {
        _task.getNotes
    }

    public var isChecked: Bool {
        _task.getIsChecked
    }
}
