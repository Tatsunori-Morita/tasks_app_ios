//
//  DetailViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/05/27.
//

import RxSwift
import RxCocoa
import RxDataSources

class DetailViewModel: BaseViewModel {
    private let _task: Task
    private let _isNewTask: Bool
    private let _detailTableViewSectionViewModels = BehaviorRelay<[TaskTableViewSectionViewModel]>(value: [])

    init(task: Task, isNewTask: Bool = false) {
        _task = task
        _isNewTask = isNewTask
        super.init()
        var sections = _detailTableViewSectionViewModels.value
        let items = task.children.map { child in
            return TaskTableViewCellViewModel(task: child)
        }
        sections.append(contentsOf: [TaskTableViewSectionViewModel(header: "", items: items)])
        _detailTableViewSectionViewModels.accept(sections)
    }

    public var detailTableViewSectionViewModelObservable: Observable<[TaskTableViewSectionViewModel]> {
        _detailTableViewSectionViewModels.asObservable()
    }

    public var detailTableViewCellViewModelArray: [TaskTableViewCellViewModel] {
        guard let section = _detailTableViewSectionViewModels.value.last else { return [] }
        return section.items
    }

    public var task: Task {
        _task
    }

    public var id: String {
        _task.id
    }

    public var text: String {
        _task.title
    }

    public var notes: String {
        _task.notes
    }

    public var isChecked: Bool {
        _task.isChecked
    }

    public var parentId: String {
        _task.parentId
    }

    public func getDetailTableViewCellViewModel(index: Int) -> TaskTableViewCellViewModel {
        let section = _detailTableViewSectionViewModels.value.last!
        if index < 0 || section.items.endIndex < index {
            fatalError("index of out of range: \(index)")
        }
        return section.items[index]
    }

    public override func moveTask(fromViewModel: TaskTableViewCellViewModel, toIndex: Int) {
        guard var section = _detailTableViewSectionViewModels.value.last else { return }
        if let index = section.items.firstIndex(where: { $0.id == fromViewModel.id }) {
            section.items.remove(at: index)
            section.items.insert(fromViewModel, at: toIndex)
            section.items = section.items.filter { !$0.title.isEmpty }
            _detailTableViewSectionViewModels.accept([section])
        }
    }

    public func addSubTaskCell() {
        guard var section = _detailTableViewSectionViewModels.value.last else { return }
        section.items.append(TaskTableViewCellViewModel(
            task: Task(title: "", notes: "", isChecked: false, parentId: _task.id, children: []),
            isNewTask: true))
        _detailTableViewSectionViewModels.accept([section])
    }

    public func updateSubTask(viewModel: TaskTableViewCellViewModel, beforeId: String) {
        guard var section = _detailTableViewSectionViewModels.value.last else { return }
        if let index = section.items.firstIndex(where: { $0.id == beforeId }) {
            // Update or delete task.
            section.items[index] = viewModel
        } else {
            // Add new task.
            section.items.append(viewModel)
        }
        save(taskTableViewSectionViewModel: section)
    }

    private func save(taskTableViewSectionViewModel: TaskTableViewSectionViewModel) {
        var section = taskTableViewSectionViewModel
        section.items = section.items.filter { !$0.title.isEmpty }
        _detailTableViewSectionViewModels.accept([section])
    }
}
