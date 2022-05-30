//
//  BaseViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/05/29.
//

import RxSwift
import RxCocoa
import RxDataSources

class BaseViewModel {
    public let _dataSource = DataSource.shared

    public var taskTableViewSectionViewModelObservable: Observable<[TaskTableViewSectionViewModel]> {
        _dataSource.taskTableViewSectionViewModelObservable
    }

    public var taskTableViewCellViewModelArray: [TaskTableViewCellViewModel] {
        _dataSource.taskTableViewCellViewModelArray
    }

    public func getTaskTableViewCellViewModel(index: Int) -> TaskTableViewCellViewModel {
        _dataSource.getTaskTableViewCellViewModel(index: index)
    }

    public func addTaskCell() {
        _dataSource.addTaskCell()
    }

    public func updateTask(viewModel: TaskTableViewCellViewModel, beforeId: String) {
        _dataSource.updateTask(viewModel: viewModel, beforeId: beforeId)
    }

    public func moveTask(fromViewModel: TaskTableViewCellViewModel, toIndex: Int) {
        _dataSource.moveTask(fromViewModel: fromViewModel, toIndex: toIndex)
    }
}
