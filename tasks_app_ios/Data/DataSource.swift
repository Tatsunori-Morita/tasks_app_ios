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
            task: Task(id: UUID().uuidString, title: "", notes: "", isChecked: false),
            isNewTask: true))
        _taskTableViewSectionViewModels.accept([section])
    }

    public func removeSubTasks(parentId: String) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        if let parentIndex = section.items.firstIndex(where: { $0.id == parentId}) {
            let parentViewModel = section.items[parentIndex]
            parentViewModel.subTasks.forEach { subTask in
                if let subTaskIndex = section.items.firstIndex(where: { $0.id == subTask.id }) {
                    section.items.remove(at: subTaskIndex)
                }
                _taskTableViewSectionViewModels.accept([section])
            }
        }
    }

    public func updateTask(viewModel: TaskTableViewCellViewModel, beforeId: String) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        if let index = section.items.firstIndex(where: { $0.id == beforeId }) {
            // Update or delete task.
            section.items[index] = viewModel

            if viewModel.isChild {
                if let parentIndex = section.items.firstIndex(where: { $0.id == viewModel.parentId}) {
                    let parentViewModel = section.items[parentIndex]
                    if viewModel.title.isEmpty {
                        // Delete.
                        let newSubTasks = parentViewModel.subTasks.filter { $0.id != beforeId }
                        let oldTask = parentViewModel.task
                        let newParentTask = oldTask.changeValues(
                            title: oldTask.title, notes: oldTask.notes,
                            isChecked: oldTask.isChecked, isShowedSubTasks: oldTask.isShowedSubTask, subTasks: newSubTasks)
                        section.items[parentIndex] = TaskTableViewCellViewModel(task: newParentTask)
                    } else {
                        // Update.
                        let subTasksViewModels = section.items.filter { $0.parentId == parentViewModel.id }
                        let subTasks = subTasksViewModels.map { $0.task }
                        let oldTask = parentViewModel.task
                        let newParentTask = oldTask.changeValues(
                            title: oldTask.title, notes: oldTask.notes,
                            isChecked: oldTask.isChecked, isShowedSubTasks: oldTask.isShowedSubTask, subTasks: subTasks)
                        section.items[parentIndex] = TaskTableViewCellViewModel(task: newParentTask)

                        if let subTaskIndex = newParentTask.subTasks.firstIndex(where: { $0.id == beforeId }) {
                            let oldSubTask = newParentTask.subTasks[subTaskIndex]
                            let newSubTask = Task(id: oldSubTask.id, title: viewModel.title,
                                                  notes: viewModel.notes, isChecked: viewModel.isChecked,
                                                  parentId: oldSubTask.parentId, subTasks: viewModel.subTasks,
                                                  isShowedSubTask: viewModel.isShowedSubTasks)
                            section.items[index] = TaskTableViewCellViewModel(task: newSubTask)
                        }
                    }
                }
            }
            save(taskTableViewSectionViewModel: section)
        }
    }

    public func insertTask(viewModels: [TaskTableViewCellViewModel], index: Int) {
        var section = _taskTableViewSectionViewModels.value.last!
        if index < 0 || section.items.endIndex < index {
            fatalError("index of out of range: \(index)")
        }
        section.items.insert(contentsOf: viewModels, at: index)
        save(taskTableViewSectionViewModel: section)
    }

    public func moveTask(fromViewModel: TaskTableViewCellViewModel, toIndex: Int) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        if let index = section.items.firstIndex(where: { $0.id == fromViewModel.id }) {
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
        printLog(data: taskTableViewSectionViewModel.items)
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
            UserDefaults.standard.set(encoded, forKey: userDefaultsName)
        }
    }

    private func printLog(data: [TaskTableViewCellViewModel]) {
        data.forEach { viewModel in
            viewModel.task.toString()
        }
    }
}
