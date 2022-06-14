//
//  TasksViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

class TasksViewModel: BaseViewModel {
    override init() {
        super.init()
        _dataSource.loadMainTasks()
    }

    public func getOpenedSubTasks(parentId: String) -> [Task] {
        _dataSource.getOpenedSubTasks(parentId: parentId)
    }

    public func hasOpenedSubTasks(parentId: String) -> Bool {
        _dataSource.hasOpenedSubTasks(parentId: parentId)
    }
}
