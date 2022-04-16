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
    private let _tasks = BehaviorRelay<[TaskTableViewSectionViewModel]>(value: [])
    private let userDefaultsName = "Tasks"

    public var tasks: BehaviorRelay<[TaskTableViewSectionViewModel]> {
        _tasks
    }

    init() {
        _tasks.accept(loadTasks)
    }

    public func addNewTask() {
        var section = _tasks.value.last!
        section.items.append(TaskTableViewCellViewModel(task: Task(text: "", isChecked: false), isNewTask: true))
        _tasks.accept([section])
    }

    public func updateTasks(viewModel: TaskTableViewCellViewModel, index: IndexPath) {
        var section = _tasks.value.last!
        section.items[index.row] = viewModel
        section.items = section.items.filter { !$0.text.isEmpty }
        if viewModel.text.isEmpty {
            _tasks.accept([TaskTableViewSectionViewModel(header: "", items: section.items)])
        } else {
            _tasks.accept([section])
        }
        saveAll(sectionViewModels: _tasks.value)
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
