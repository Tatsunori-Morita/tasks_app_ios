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

    public func changeTitle(viewModel: TaskTableViewCellViewModel, beforeId: String) {
        _dataSource.changeTitle(viewModel: viewModel, beforeId: beforeId)
        _dataSource.saveSectionViewModelIntoUserDefaults()
    }

    public func changeCheckMark(viewModel: TaskTableViewCellViewModel, beforeId: String) {
        _dataSource.changeCheckMark(viewModel: viewModel, beforeId: beforeId)
        _dataSource.saveSectionViewModelIntoUserDefaults()
    }

    public func removeTask(viewModel: TaskTableViewCellViewModel) {
        _dataSource.removeTask(viewModel: viewModel)
        _dataSource.saveSectionViewModelIntoUserDefaults()
    }

    public func moveTask(fromIndex: Int, toIndex: Int) {
        _dataSource.moveTask(fromIndex: fromIndex, toIndex: toIndex)
        _dataSource.saveSectionViewModelIntoUserDefaults()
    }

    public func insertTask(fromIndex: Int, toIndex: Int) {
        _dataSource.insertTask(fromIndex: fromIndex, toIndex: toIndex)
        _dataSource.saveSectionViewModelIntoUserDefaults()
    }

    public func getTaskTableViewModel(id: String) -> TaskTableViewCellViewModel {
        guard let index = taskTableViewCellViewModelArray.firstIndex(where: { $0.taskId == id}) else {
            fatalError("getTaskTableViewModel: index of out of range")
        }
        return getTaskTableViewCellViewModel(index: index)
    }

    public func openedSubTasks(newParentViewModel: TaskTableViewCellViewModel) {
        _dataSource.openedSubTasks(newParentViewModel: newParentViewModel)
        _dataSource.saveSectionViewModelIntoUserDefaults()
    }

    public func closedSubTasks(newParentViewModel: TaskTableViewCellViewModel) {
        _dataSource.closedSubTasks(newParentViewModel: newParentViewModel)
        _dataSource.saveSectionViewModelIntoUserDefaults()
    }
}
