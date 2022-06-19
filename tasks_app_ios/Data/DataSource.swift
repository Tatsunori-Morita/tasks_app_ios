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

    public func hasOpenedSubTasks(parentId: String) -> Bool {
        getOpenedSubTasks(parentId: parentId).count > 0
    }

    public func addTaskCell() {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        section.items.append(TaskTableViewCellViewModel(
            task: Task(id: UUID().uuidString, title: "", notes: "", isChecked: false),
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

            if viewModel.isChild && viewModel.title.isEmpty && getOpenedSubTasks(parentId: viewModel.parentId).isEmpty {
                // If Parent task has not sub tasks, update Parent task subtasks property.
                guard
                    let parentIndex = section.items.firstIndex(where: { $0.taskId == viewModel.parentId })
                else { fatalError("updateTask:not found parent index.") }
                let oldParentViewModel = section.items[parentIndex]
                let oldParentTask = oldParentViewModel.task
                let newParentTask = oldParentTask.changeValue(isShowedSubTasks: false, subTasks: [])
                section.items[parentIndex] = TaskTableViewCellViewModel(task: newParentTask)
                save(taskTableViewSectionViewModel: section)
            }

            if !viewModel.isChild {
                let subTasks = viewModel.isShowedSubTasks ? getOpenedSubTasks(parentId: viewModel.taskId) : viewModel.subTasks
                subTasks.forEach { subTask in
                    if let index = section.items.firstIndex(where: { $0.taskId == subTask.id }) {
                        let newTask = subTask.changeValue(isChecked: viewModel.isChecked)
                        section.items[index] = TaskTableViewCellViewModel(task: newTask)
                    }
                }

                if viewModel.title.isEmpty && viewModel.isShowedSubTasks {
                    let subTasks = getOpenedSubTasks(parentId: viewModel.taskId)
                    subTasks.forEach { subTask in
                        if let index = section.items.firstIndex(where: { $0.taskId == subTask.id }) {
                            let newTask = subTask.changeValue(title: "")
                            section.items[index] = TaskTableViewCellViewModel(task: newTask)
                        }
                    }
                }

                save(taskTableViewSectionViewModel: section)
            }
        }
    }

    public func openedSubTasks(newParentViewModel: TaskTableViewCellViewModel) {
        guard
            var section = _taskTableViewSectionViewModels.value.last,
            let parentIndex = section.items.firstIndex(where: { $0.taskId == newParentViewModel.taskId }) else {
            fatalError("openedSubTasks:not found parent index.")
        }
        let oldParentTask = section.items[parentIndex].task
        let newParentViewModel = TaskTableViewCellViewModel(task: oldParentTask.changeValue(isShowedSubTasks: true, subTasks: []))
        section.items[parentIndex] = newParentViewModel

        let subTaskViewModels = oldParentTask.subTasks.map { subTask in
            return TaskTableViewCellViewModel(task: subTask)
        }

        section.items.insert(contentsOf: subTaskViewModels, at: parentIndex + 1)
        save(taskTableViewSectionViewModel: section)
    }

    public func closedSubTasks(newParentViewModel: TaskTableViewCellViewModel) {
        guard
            var section = _taskTableViewSectionViewModels.value.last,
            let parentIndex = section.items.firstIndex(where: { $0.taskId == newParentViewModel.taskId })
        else { fatalError("closedSubTasks:not found parent index.") }
        let subTaskViewModels = section.items.filter { $0.parentId == newParentViewModel.taskId}
        subTaskViewModels.forEach { subTaskViewModel in
            if let subTaskIndex = section.items.firstIndex(where: { $0.taskId == subTaskViewModel.taskId }) {
                section.items.remove(at: subTaskIndex)
            }
        }

        let subTasks = newParentViewModel.subTasks.isEmpty ? subTaskViewModels.map { $0.task } : newParentViewModel.subTasks
        let oldParentTask = newParentViewModel.task
        let newParentTask = oldParentTask.changeValue(isShowedSubTasks: false, subTasks: subTasks)
        section.items[parentIndex] = TaskTableViewCellViewModel(task: newParentTask)
        save(taskTableViewSectionViewModel: section)
    }

    public func moveTask(fromIndex: Int, toIndex: Int) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        let fromViewModel = getTaskTableViewCellViewModel(index: fromIndex)
        if let index = section.items.firstIndex(where: { $0.taskId == fromViewModel.taskId }) {
            section.items.remove(at: index)
            section.items.insert(fromViewModel, at: toIndex)

            let oldTask = fromViewModel.task
            let newTask: Task!
            if toIndex == 0 {
                newTask = oldTask.changeValue(parentId: "")
            } else {
                let topTaskTableViewModel = section.items[toIndex - 1]
                let parentId = topTaskTableViewModel.parentId.isEmpty ? (topTaskTableViewModel.isShowedSubTasks ? topTaskTableViewModel.taskId : "") : topTaskTableViewModel.parentId
                newTask = oldTask.changeValue(parentId: parentId)
            }

            section.items[toIndex] = TaskTableViewCellViewModel(task: newTask)
            save(taskTableViewSectionViewModel: TaskTableViewSectionViewModel(header: "", items: section.items))
        }
    }

    public func insertTask(fromIndex: Int, toIndex: Int) {
        guard var section = _taskTableViewSectionViewModels.value.last else { return }
        let fromViewModel = section.items[fromIndex]
        section.items.remove(at: fromIndex)
        let newToIndex = section.items.count == toIndex ? section.items.count - 1 : toIndex
        let toViewModel = section.items[newToIndex]

        if fromViewModel.hasSubTasks || !toViewModel.parentId.isEmpty {
            return
        }

        let oldFromTask = fromViewModel.task
        let oldToTask = toViewModel.task
        let newFromTask: Task!
        let newToTask: Task!

        if toViewModel.isShowedSubTasks {
            newFromTask = oldFromTask.changeValue(parentId: toViewModel.taskId)
            section.items.insert(TaskTableViewCellViewModel(task: newFromTask), at: toIndex + 1)
        } else {
            newFromTask = oldFromTask.changeValue(parentId: toViewModel.taskId)
            var oldSubTasks = toViewModel.subTasks
            oldSubTasks.append(newFromTask)
            newToTask = oldToTask.changeValue(isShowedSubTasks: false, subTasks: oldSubTasks)
            section.items[toIndex] = TaskTableViewCellViewModel(task: newToTask)
        }
        save(taskTableViewSectionViewModel: TaskTableViewSectionViewModel(header: "", items: section.items))
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
