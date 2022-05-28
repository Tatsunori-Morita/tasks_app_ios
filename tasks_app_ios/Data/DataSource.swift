//
//  Data.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/05/14.
//

import Foundation

class DataSource {
    public static let shared = DataSource()

    private let userDefaultsName = "Tasks"
    
    public func saveAll(sectionViewModels: [TaskTableViewSectionViewModel]) {
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

    public var loadTasks: [TaskTableViewSectionViewModel] {
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

    public func loadSubTasks(parentId: String) -> [TaskTableViewSectionViewModel] {
        guard
            let objects = UserDefaults.standard.value(forKey: userDefaultsName) as? Data,
            let taskModels = try? JSONDecoder().decode(Array.self, from: objects) as [Task],
            !parentId.isEmpty
        else { return [TaskTableViewSectionViewModel(header: "", items: [])] }
        var cellViewModels: [TaskTableViewCellViewModel] = []
        taskModels.filter { model in model.getParentId == parentId }.forEach { taskModel in
            cellViewModels.append(TaskTableViewCellViewModel(task: taskModel))
        }
        return [TaskTableViewSectionViewModel(header: "", items: cellViewModels)]
    }
}
