//
//  Data.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/05/14.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

class DataSource {
    public static let shared = DataSource()

    private let _taskTableViewSectionViewModels = BehaviorRelay<[TaskTableViewSectionViewModel]>(value: [])
    private let userDefaultsName = "Tasks"

    public var taskTableViewSectionViewModelObservable: Observable<[TaskTableViewSectionViewModel]> {
        _taskTableViewSectionViewModels.asObservable()
    }

    public var taskTableViewCellViewModelArray: [TaskTableViewCellViewModel] {
        guard let section = _taskTableViewSectionViewModels.value.last else { return [] }
        return section.items
    }

    public func getTaskTableViewCellViewModel(index: Int) -> TaskTableViewCellViewModel {
        let section = _taskTableViewSectionViewModels.value.last!
        if index < 0 || section.items.endIndex < index {
            fatalError("index of out of range: \(index)")
        }
        return section.items[index]
    }

    public func addTaskCell() {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        section.items.append(TaskTableViewCellViewModel(
            task: Task(title: "", isChecked: false),
            isNewTask: true))
        _taskTableViewSectionViewModels.accept([section])
    }

    public func updateTask(viewModel: TaskTableViewCellViewModel, beforeId: String) {
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

    public func moveTask(fromViewModel: TaskTableViewCellViewModel, toIndex: Int) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        if let index = section.items.firstIndex(where: { $0.getId == fromViewModel.getId }) {
            section.items.remove(at: index)
            section.items.insert(fromViewModel, at: toIndex)
            save(taskTableViewSectionViewModel: section)
        }
    }

    public func loadMainTasks() {
        guard
            let objects = UserDefaults.standard.value(forKey: userDefaultsName) as? Data,
            let taskModels = try? JSONDecoder().decode(Array.self, from: objects) as [Task]
        else { return }

        var cellViewModels: [TaskTableViewCellViewModel] = []
        taskModels.forEach { taskModel in
            cellViewModels.append(TaskTableViewCellViewModel(task: taskModel))
        }
        let sections = [TaskTableViewSectionViewModel(header: "", items: cellViewModels)]
        _taskTableViewSectionViewModels.accept(sections)
    }

    public func loadSubTasks(parentId: String) {
        guard
            let objects = UserDefaults.standard.value(forKey: userDefaultsName) as? Data,
            let taskModels = try? JSONDecoder().decode(Array.self, from: objects) as [Task],
            !parentId.isEmpty
        else { return }

        var cellViewModels: [TaskTableViewCellViewModel] = []
        taskModels.filter { model in model.getParentId == parentId }.forEach { taskModel in
            cellViewModels.append(TaskTableViewCellViewModel(task: taskModel))
        }
    }

    private func save(taskTableViewSectionViewModel: TaskTableViewSectionViewModel) {
        var section = taskTableViewSectionViewModel
        section.items = section.items.filter { !$0.text.isEmpty }
        _taskTableViewSectionViewModels.accept([section])
        saveUserDefaults(sectionViewModels: _taskTableViewSectionViewModels.value)
    }

    private func saveUserDefaults(sectionViewModels: [TaskTableViewSectionViewModel]) {
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
}
