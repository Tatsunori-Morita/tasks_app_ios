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
}
