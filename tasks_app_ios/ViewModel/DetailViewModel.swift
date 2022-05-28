//
//  DetailViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/05/27.
//

import RxSwift
import RxCocoa
import RxDataSources

class DetailViewModel {
    private let _task: Task
    private let _isNewTask: Bool
    private let _taskTableViewSectionViewModels = BehaviorRelay<[TaskTableViewSectionViewModel]>(value: [])
    private let _dataSource = DataSource.shared

    init(task: Task, isNewTask: Bool = false, parentId: String = "") {
        _task = task
        _isNewTask = isNewTask
//        _taskTableViewSectionViewModels.accept(_dataSource.loadSubTasks(parentId: parentId))
    }

    public var task: Task {
        _task
    }

    public var text: String {
        _task.getTitle
    }

    public var taskTableViewSectionViewModelBehaviorRelay: Observable<[TaskTableViewSectionViewModel]> {
        _taskTableViewSectionViewModels.asObservable()
    }

    public var taskTableViewCellViewModelArray: [TaskTableViewCellViewModel] {
        guard let section = _taskTableViewSectionViewModels.value.last else { return [] }
        return section.items
    }

    public func getTaskTableViewCellViewModel(index: Int) -> TaskTableViewCellViewModel {
        let section = _taskTableViewSectionViewModels.value.last!
        return section.items[index]
    }

    public func addNewTask() {
//        guard var section = _taskTableViewSectionViewModels.value.last else { return }
//        section.items.append(TaskTableViewCellViewModel(
//            task: Task(title: "", isChecked: false),
//            isNewTask: true))
//        _taskTableViewSectionViewModels.accept([section])
    }

    public func updateTasks(viewModel: TaskTableViewCellViewModel, beforeId: String) {
//        guard var section = _taskTableViewSectionViewModels.value.last else { return }
//        if let index = section.items.firstIndex(where: { $0.getId == beforeId }) {
//            // Update or delete task.
//            section.items[index] = viewModel
//        } else {
//            // Add new task.
//            section.items.append(viewModel)
//        }
//        save(taskTableViewSectionViewModel: section)
    }

    public func updateTasks(viewModel: TaskTableViewCellViewModel, fromIndex: Int, toIndex: Int) {
//        guard var section = _taskTableViewSectionViewModels.value.last else { return }
//        section.items.remove(at: fromIndex)
//        section.items.insert(viewModel, at: toIndex)
//        save(taskTableViewSectionViewModel: section)
    }

//    private func save(taskTableViewSectionViewModel: TaskTableViewSectionViewModel) {
//        var section = taskTableViewSectionViewModel
//        section.items = section.items.filter { !$0.text.isEmpty }
//        _taskTableViewSectionViewModels.accept([section])
//        _dataSource.saveAll(sectionViewModels: _taskTableViewSectionViewModels.value)
//    }
}
