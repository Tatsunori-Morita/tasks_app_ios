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

final class DataSource {
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
            task: Task(id: UUID().uuidString, title: "", notes: "", isChecked: false, hasSubTasks: false),
            isNewTask: true))
        _taskTableViewSectionViewModels.accept([section])
    }

    public func getOpenedSubTasks(parentId: String) -> [Task] {
        guard let section = _taskTableViewSectionViewModels.value.last else { return [] }
        let subTaskViewModels = section.items.filter { $0.parentId == parentId}
        return subTaskViewModels.map { $0.task }
    }

    public func updateTask(viewModel: TaskTableViewCellViewModel, beforeId: String) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        if let index = section.items.firstIndex(where: { $0.taskId == beforeId }) {
            // Update or delete task.
            section.items[index] = viewModel
            save(taskTableViewSectionViewModel: section)
        }
    }

    public func openedSubTasks(newParentViewModel: TaskTableViewCellViewModel) {
        guard
            var section = _taskTableViewSectionViewModels.value.last,
            let parentIndex = section.items.firstIndex(where: { $0.taskId == newParentViewModel.taskId }) else {
            fatalError("not found parent index.")
        }
        let parentViewModel = section.items[parentIndex]
        let newParentViewModel = TaskTableViewCellViewModel(
            task: parentViewModel.task.changeValues(
                title: parentViewModel.title, notes: parentViewModel.notes,
                isChecked: parentViewModel.isChecked, isShowedSubTasks: true,
                hasSubTasks: true, subTasks: []))
        section.items[parentIndex] = newParentViewModel

        let subTaskViewModels = parentViewModel.subTasks.map { subTask in
            return TaskTableViewCellViewModel(task: subTask)
        }

        section.items.insert(contentsOf: subTaskViewModels, at: parentIndex + 1)
        save(taskTableViewSectionViewModel: section)
    }

    public func closedSubTasks(newParentViewModel: TaskTableViewCellViewModel) {
        guard
            var section = _taskTableViewSectionViewModels.value.last,
            let parentIndex = section.items.firstIndex(where: { $0.taskId == newParentViewModel.taskId })
        else { fatalError("not found parent index.") }
        let subTaskViewModels = section.items.filter { $0.parentId == newParentViewModel.taskId}
        subTaskViewModels.forEach { subTaskViewModel in
            if let subTaskIndex = section.items.firstIndex(where: { $0.taskId == subTaskViewModel.taskId }) {
                section.items.remove(at: subTaskIndex)
            }
        }

        let subTasks = newParentViewModel.subTasks.isEmpty ? subTaskViewModels.map { $0.task } : newParentViewModel.subTasks

        let newParentTask = newParentViewModel.task.changeValues(
            title: newParentViewModel.title, notes: newParentViewModel.notes,
            isChecked: newParentViewModel.isChecked,isShowedSubTasks: false,
            hasSubTasks: true, subTasks: subTasks)
        section.items[parentIndex] = TaskTableViewCellViewModel(task: newParentTask)
        save(taskTableViewSectionViewModel: section)
    }

    public func moveTask(fromViewModel: TaskTableViewCellViewModel, toIndex: Int) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        if let index = section.items.firstIndex(where: { $0.taskId == fromViewModel.taskId }) {
            section.items.remove(at: index)
            section.items.insert(fromViewModel, at: toIndex)
            save(taskTableViewSectionViewModel: section)
        }
    }

    public func loadMainTasks() {
        let cellViewModels = loadTasks().map { task in
            return TaskTableViewCellViewModel(task: task)
        }
        let sections = [TaskTableViewSectionViewModel(header: "", items: cellViewModels)]
        _taskTableViewSectionViewModels.accept(sections)
    }

    private func loadTasks() -> [Task] {
        guard
            let objects = UserDefaults.standard.value(forKey: userDefaultsName) as? Data,
            let tasks = try? JSONDecoder().decode(Array.self, from: objects) as [Task]
        else { return [] }
        return tasks
    }

    private func save(taskTableViewSectionViewModel: TaskTableViewSectionViewModel) {
        var section = taskTableViewSectionViewModel
        section.items = section.items.filter { !$0.title.isEmpty }
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
            print("======================== Data Log Start ==========================")
            print(String(data: encoded, encoding: .utf8)!)
            print("======================== Data Log End ==========================")
            UserDefaults.standard.set(encoded, forKey: userDefaultsName)
        }
    }

    private func printLog(data: [TaskTableViewCellViewModel]) {
        data.forEach { viewModel in
            viewModel.task.toString()
        }
    }
}
