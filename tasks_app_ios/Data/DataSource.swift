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

    private let _taskTableViewSectionViewModels = BehaviorRelay<[TaskTableViewSectionViewModel]>(value: [TaskTableViewSectionViewModel(header: "", items: [])])
    private let _userDefaultsName = "Tasks"

    public var taskTableViewSectionViewModelObservable: Observable<[TaskTableViewSectionViewModel]> {
        _taskTableViewSectionViewModels.asObservable()
    }

    public var taskTableViewCellViewModelArray: [TaskTableViewCellViewModel] {
        guard let section = _taskTableViewSectionViewModels.value.last else { return [] }
        return section.items
    }

    public func getTaskTableViewCellViewModel(index: Int) -> TaskTableViewCellViewModel {
        let section = getSectionViewModel()
        if index < 0 || section.items.endIndex < index {
            fatalError("index of out range: \(index)")
        }
        return section.items[index]
    }

    public func getTaskTableViewCellViewModel(taskId: String) -> TaskTableViewCellViewModel {
        let section = getSectionViewModel()
        let index = getTaskIdOfSectionItems(taskId: taskId)
        return section.items[index]
    }

    private func getSectionViewModel() -> TaskTableViewSectionViewModel {
        guard
            let section = _taskTableViewSectionViewModels.value.last
        else {
            fatalError("sectionViewModel is nil.")
        }
        return section
    }

    private func getTaskIdOfSectionItems(taskId: String) -> Int {
        let section = getSectionViewModel()
        guard
            let index = section.items.firstIndex(where: { $0.taskId == taskId })
        else {
            fatalError("found not task id.")
        }
        return index
    }

    public func hasTaskId(taskId: String) -> Bool {
        let section = getSectionViewModel()
        guard
            let _ = section.items.firstIndex(where: { $0.taskId == taskId })
        else {
            return false
        }
        return true
    }

    public func hasOpenedSubTasks(parentId: String) -> Bool {
        getOpenedSubTasks(parentId: parentId).count > 0
    }

    public func addTaskCell() {
        addTask(task: Task.createNewTask(), isNewTask: true)
    }

    public func addTask(task: Task, isNewTask: Bool = false) {
        var section = getSectionViewModel()
        section.items.append(
            TaskTableViewCellViewModel(
                task: task,
                isNewTask: isNewTask))
        _taskTableViewSectionViewModels.accept([section])
    }

    public func getOpenedSubTasks(parentId: String) -> [Task] {
        let section = getSectionViewModel()
        let subTaskViewModels = section.items.filter { $0.parentId == parentId}
        return subTaskViewModels.map { $0.task }
    }

    public func saveDetailValues(viewModel: TaskTableViewCellViewModel) {
        var section = getSectionViewModel()
        let index = getTaskIdOfSectionItems(taskId: viewModel.taskId)
        section.items[index] = viewModel
        saveBehaviorRelay(taskTableViewSectionViewModel: section)
    }

    public func changeTitle(viewModel: TaskTableViewCellViewModel) {
        var section = getSectionViewModel()
        let index = getTaskIdOfSectionItems(taskId: viewModel.taskId)

        section.items[index] = viewModel

        if viewModel.isChild && viewModel.title.isEmpty && getOpenedSubTasks(parentId: viewModel.parentId).count == 1 {
            // If Parent task has not sub tasks, update task subtasks property of Parent.
            let parentIndex = getTaskIdOfSectionItems(taskId: viewModel.parentId)
            let oldParentViewModel = section.items[parentIndex]
            let oldParentTask = oldParentViewModel.task
            let newParentTask = oldParentTask.changeValue(isShowedSubTasks: false, subTasks: [])
            section.items[parentIndex] = TaskTableViewCellViewModel(task: newParentTask)
        }
        saveBehaviorRelay(taskTableViewSectionViewModel: section)
    }

    public func removeTask(viewModel: TaskTableViewCellViewModel) {
        var section = getSectionViewModel()
        let index = getTaskIdOfSectionItems(taskId: viewModel.taskId)
        section.items.remove(at: index)

        if !viewModel.isChild && viewModel.isShowedSubTasks {
            let subTasks = getOpenedSubTasks(parentId: viewModel.taskId)
            subTasks.forEach { subTask in
                if let subTaskIndex = section.items.firstIndex(where: { $0.taskId == subTask.id }) {
                    section.items.remove(at: subTaskIndex)
                }
            }
        }
        saveBehaviorRelay(taskTableViewSectionViewModel: section)
    }

    public func changeCheckMark(viewModel: TaskTableViewCellViewModel) {
        var section = getSectionViewModel()
        let index = getTaskIdOfSectionItems(taskId: viewModel.taskId)
        section.items[index] = viewModel

        if !viewModel.isChild {
            // Change Sub task checkmark.
            let subTasks = viewModel.isShowedSubTasks ? getOpenedSubTasks(parentId: viewModel.taskId) : viewModel.subTasks
            subTasks.forEach { subTask in
                let index = getTaskIdOfSectionItems(taskId: subTask.id)
                let newTask = subTask.changeValue(isChecked: viewModel.isChecked)
                section.items[index] = TaskTableViewCellViewModel(task: newTask)
            }
        }
        saveBehaviorRelay(taskTableViewSectionViewModel: section)
    }

    public func openedSubTasks(newParentViewModel: TaskTableViewCellViewModel) {
        var section = getSectionViewModel()
        let parentIndex = getTaskIdOfSectionItems(taskId: newParentViewModel.taskId)
        let oldParentTask = section.items[parentIndex].task
        let newParentViewModel = TaskTableViewCellViewModel(
            task: oldParentTask.changeValue(isShowedSubTasks: true, subTasks: []))
        section.items[parentIndex] = newParentViewModel

        let subTaskViewModels = oldParentTask.subTasks.map { subTask in
            return TaskTableViewCellViewModel(task: subTask)
        }

        section.items.insert(contentsOf: subTaskViewModels, at: parentIndex + 1)
        saveBehaviorRelay(taskTableViewSectionViewModel: section)
    }

    public func closedSubTasks(newParentViewModel: TaskTableViewCellViewModel) {
        var section = getSectionViewModel()
        let parentIndex = getTaskIdOfSectionItems(taskId: newParentViewModel.taskId)
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
        saveBehaviorRelay(taskTableViewSectionViewModel: section)
    }

    public func moveTask(fromIndex: Int, toIndex: Int) {
        var section = getSectionViewModel()
        let fromViewModel = getTaskTableViewCellViewModel(index: fromIndex)
        let index = getTaskIdOfSectionItems(taskId: fromViewModel.taskId)
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
        saveBehaviorRelay(taskTableViewSectionViewModel: TaskTableViewSectionViewModel(header: "", items: section.items))
    }

    public func insertTask(fromIndex: Int, toIndex: Int) {
        var section = getSectionViewModel()
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
        saveBehaviorRelay(taskTableViewSectionViewModel: TaskTableViewSectionViewModel(header: "", items: section.items))
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
            let objects = UserDefaults.standard.value(forKey: _userDefaultsName) as? Data,
            let tasks = try? JSONDecoder().decode(Array.self, from: objects) as [Task]
        else { return [] }
        return tasks
    }

    private func saveBehaviorRelay(taskTableViewSectionViewModel: TaskTableViewSectionViewModel) {
        var section = taskTableViewSectionViewModel
        section.items = section.items.filter { !$0.title.isEmpty }
        _taskTableViewSectionViewModels.accept([section])
    }

    public func saveSectionViewModelIntoUserDefaults() {
        let section = getSectionViewModel()
        let taskModels = section.items.map { $0.task }

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(taskModels){
            print("======================== Data Log Start ==========================")
            print(String(data: encoded, encoding: .utf8)!)
            print("======================== Data Log End ==========================")
            UserDefaults.standard.set(encoded, forKey: _userDefaultsName)
        }
    }

    public func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: _userDefaultsName)
    }

    public func clearBehaviorRelay() {
        _taskTableViewSectionViewModels.accept([TaskTableViewSectionViewModel(header: "", items: [])])
    }

    public func log() {
        let section = getSectionViewModel()
        section.items.forEach { cellViewModel in
            print(cellViewModel.task.toString())
        }
    }
}
