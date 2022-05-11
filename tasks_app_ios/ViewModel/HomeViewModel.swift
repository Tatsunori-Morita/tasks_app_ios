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
    private let userDefaultsName = "Tasks"

    public var taskTableViewSectionViewModelBehaviorRelay: BehaviorRelay<[TaskTableViewSectionViewModel]> {
        _taskTableViewSectionViewModels
    }

    public var taskTableViewCellViewModellArray: [TaskTableViewCellViewModel] {
        let section = taskTableViewSectionViewModelBehaviorRelay.value.last!
        return section.items
    }

    init() {
        _taskTableViewSectionViewModels.accept(loadTasks)
    }

    public func getTaskTableViewCellViewModel(index: Int) -> TaskTableViewCellViewModel {
        let section = _taskTableViewSectionViewModels.value.last!
        return section.items[index]
    }

    public func addNewTask() {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        section.items.append(TaskTableViewCellViewModel(task: Task(text: "", isChecked: false), isNewTask: true))
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
        section.items = section.items.filter { !$0.text.isEmpty }
        _taskTableViewSectionViewModels.accept([section])
        saveAll(sectionViewModels: _taskTableViewSectionViewModels.value)
    }

    private func saveAll(sectionViewModels: [TaskTableViewSectionViewModel]) {
        var taskModels: [Task] = []
        for sectionViewModel in sectionViewModels {
            for cellViewModel in sectionViewModel.items {
                taskModels.append(cellViewModel.task)
            }
        }
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(taskModels){
            UserDefaults.standard.set(encoded, forKey: userDefaultsName)
        }
    }

    private var loadTasks: [TaskTableViewSectionViewModel] {
        guard
            let objects = UserDefaults.standard.value(forKey: userDefaultsName) as? Data,
            let taskModels = try? JSONDecoder().decode(Array.self, from: objects) as [Task]
        else { return [TaskTableViewSectionViewModel(header: "", items: [])] }
        var cellViewModels: [TaskTableViewCellViewModel] = []
        taskModels.forEach { taskModel in
            cellViewModels.append(TaskTableViewCellViewModel(task: taskModel))
        }
        return [TaskTableViewSectionViewModel(header: "", items: cellViewModels)]
    }
}
