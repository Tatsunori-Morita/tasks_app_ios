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
    private var _tasks = BehaviorRelay<[TaskTableViewSectionViewModel]>(value: [])
    private let userDefaultsName = "Tasks"

    public var tasks: BehaviorRelay<[TaskTableViewSectionViewModel]> {
        _tasks
    }

    init() {
        _tasks.accept(loadTasks)
    }

    public func addNewItem() {
        var section = _tasks.value.last!
        section.items.append(TaskTableViewCellViewModel(text: "", isChecked: false, isNewTask: true))
        _tasks.accept([section])
    }

    public func updateItems(viewModel: TaskTableViewCellViewModel, index: IndexPath) {
        var section = _tasks.value.last!
        section.items[index.row] = viewModel
        section.items = section.items.filter { !$0.text.isEmpty }
        if viewModel.text.isEmpty {
            _tasks.accept([TaskTableViewSectionViewModel(header: "", items: section.items)])
        } else {
            _tasks.accept([section])
        }
        saveAll(tasks: _tasks.value)
    }

    private func saveAll(tasks: [TaskTableViewSectionViewModel]) {
         let encoder = JSONEncoder()
         if let encoded = try? encoder.encode(tasks){
            UserDefaults.standard.set(encoded, forKey: userDefaultsName)
         }
    }

    private var loadTasks: [TaskTableViewSectionViewModel] {
        guard
            let objects = UserDefaults.standard.value(forKey: userDefaultsName) as? Data,
            let tasks = try? JSONDecoder().decode(Array.self, from: objects) as [TaskTableViewSectionViewModel]
        else { return [TaskTableViewSectionViewModel(header: "", items: [])] }
        return tasks
    }
}
