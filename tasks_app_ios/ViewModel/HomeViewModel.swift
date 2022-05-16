//
//  HomeViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

import RxSwift
import RxCocoa
import RxDataSources

struct HomeViewModel {
    private let _taskTableViewSectionViewModels = BehaviorRelay<[TaskTableViewSectionViewModel]>(value: [])
    private let _dataSource = DataSource.shared

    public var taskTableViewSectionViewModelBehaviorRelay: Observable<[TaskTableViewSectionViewModel]> {
        _taskTableViewSectionViewModels.asObservable()
    }

    public var taskTableViewCellViewModelArray: [TaskTableViewCellViewModel] {
        guard let section = _taskTableViewSectionViewModels.value.last else { return [] }
        return section.items
    }

    init() {
        _taskTableViewSectionViewModels.accept(_dataSource.loadTasks)
    }

    public func getTaskTableViewCellViewModel(index: Int) -> TaskTableViewCellViewModel {
        let section = _taskTableViewSectionViewModels.value.last!
        return section.items[index]
    }

    public func addNewTask() {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        section.items.append(TaskTableViewCellViewModel(
            task: Task(text: "", isChecked: false),
            isNewTask: true))
        _taskTableViewSectionViewModels.accept([section])
    }

    public func updateTasks(viewModel: TaskTableViewCellViewModel, beforeId: String) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        if let index = section.items.firstIndex(where: { $0.getId == beforeId }) {
            // Update or delete task.
            section.items[index] = viewModel
        } else {
            // Add new task.
            section.items.append(viewModel)
        }
        save(taskTableViewSectionViewModel: section)
    }

    public func updateTasks(viewModel: TaskTableViewCellViewModel, fromIndex: Int, toIndex: Int) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        section.items.remove(at: fromIndex)
        section.items.insert(viewModel, at: toIndex)
        save(taskTableViewSectionViewModel: section)
    }

    private func save(taskTableViewSectionViewModel: TaskTableViewSectionViewModel) {
        var section = taskTableViewSectionViewModel
        section.items = section.items.filter { !$0.text.isEmpty }
        _taskTableViewSectionViewModels.accept([section])
        _dataSource.saveAll(sectionViewModels: _taskTableViewSectionViewModels.value)
    }
}
