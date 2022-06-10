//
//  TasksViewController.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import IQKeyboardManagerSwift

class TasksViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addTaskButton: UIButton!

    private static let identifier = String(describing: TasksViewController.self)
    private let disposeBag = DisposeBag()
    private let tasksViewModel = TasksViewModel()
    private var tableViewContentOffset: CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }

    public static func createInstance() -> TasksViewController {
        let storyboard = UIStoryboard(name: self.identifier, bundle: nil)
        let instance = storyboard.instantiateViewController(withIdentifier: self.identifier) as! TasksViewController
        return instance
    }

    private func initialize() {
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        tableView.register(
            UINib(nibName: TaskTableViewCell.identifier, bundle: nil),
            forCellReuseIdentifier: TaskTableViewCell.identifier)

        // Set tableView.
        tasksViewModel.taskTableViewSectionViewModelObservable
            .bind(to: tableView.rx.items(dataSource: dataSource()))
            .disposed(by: disposeBag)

        // Delete cell.
        tableView.rx.itemDeleted.asDriver().drive(with: self, onNext: { owner, indexPath in
            let oldViewModel = owner.tasksViewModel.getTaskTableViewCellViewModel(index: indexPath.row)
            let newTask = oldViewModel.task.changeValues(
                title: "", notes: oldViewModel.notes, isChecked: oldViewModel.isChecked,
                isShowedSubTasks: oldViewModel.isShowedSubTasks, subTasks: oldViewModel.subTasks)
            let newViewModel = TaskTableViewCellViewModel(task: newTask, isNewTask: true)
            owner.tasksViewModel.updateTask(viewModel: newViewModel, beforeId: oldViewModel.id)
        }).disposed(by: disposeBag)

        // Move cell.
        tableView.rx.itemMoved.asDriver().drive(with: self, onNext: { owner, values in
            let (fromIndexPath, toIndexPath) = values
            guard fromIndexPath != toIndexPath else { return }
            let fromIndexPathViewModel = owner.tasksViewModel.getTaskTableViewCellViewModel(index: fromIndexPath.row)
            owner.tasksViewModel.moveTask(fromViewModel: fromIndexPathViewModel, toIndex: toIndexPath.row)
        }).disposed(by: disposeBag)

        // Add new cell.
        addTaskButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
            DispatchQueue.main.async {
                owner.tasksViewModel.addTaskCell()
                let indexPath = IndexPath(row: owner.tasksViewModel.taskTableViewCellViewModelArray.count - 1, section: 0)
                owner.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                if let cell = owner.tableView.cellForRow(at: indexPath) as? TaskTableViewCell {
                    cell.textView.becomeFirstResponder()
                }
            }
        }).disposed(by: disposeBag)
    }
}

extension TasksViewController {
    @objc private func keyboardWillShow(notification: NSNotification) {
        addTaskButton.isHidden = true
        tableViewContentOffset = tableView.contentOffset
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
     }

     @objc private func keyboardWillHide(notification: NSNotification) {
         DispatchQueue.main.async { [unowned self] in
             self.addTaskButton.isHidden = false
             UIView.animate(withDuration: 0.2, animations: {
                 if let unwrappedOffset = self.tableViewContentOffset {
                     self.tableView.contentOffset = unwrappedOffset
                 }
                 self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
             })
         }
     }
}

extension TasksViewController: UITableViewDropDelegate, UITableViewDragDelegate {
    private func dataSource() -> RxTableViewSectionedAnimatedDataSource<TaskTableViewSectionViewModel> {
        return RxTableViewSectionedAnimatedDataSource(animationConfiguration: AnimationConfiguration(insertAnimation: .none, reloadAnimation: .none, deleteAnimation: .none), configureCell: { [self] dataSource, tableView, indexPath, viewModel in
            let cell = tableView.dequeueReusableCell(withIdentifier: TaskTableViewCell.identifier, for: indexPath) as! TaskTableViewCell
            cell.configure(viewModel: viewModel)

            cell.textView.rx.didChange.asDriver().drive(with: self, onNext: { owner, _ in
                tableView.beginUpdates()
                tableView.endUpdates()
            }).disposed(by: cell.disposeBag)

            cell.textView.rx.didBeginEditing.asDriver().drive(with: self, onNext: { owner, _ in 
                cell.infoButton.isHidden = viewModel.isChild
                cell.subTasksButton.isHidden = true
            }).disposed(by: cell.disposeBag)

            cell.textView.rx.didEndEditing
                .map { cell.textView.text }
                .filter { $0 != nil }
                .map { $0! }
                .subscribe(onNext: { newText in
                    cell.infoButton.isHidden = true
                    let oldTask = viewModel.task
                    let newViewModel = TaskTableViewCellViewModel(
                        task: oldTask.changeValues(
                            title: newText, notes: oldTask.notes,
                            isChecked: oldTask.isChecked, isShowedSubTasks: oldTask.isShowedSubTask))
                    self.tasksViewModel.updateTask(viewModel: newViewModel, beforeId: viewModel.id)
                }).disposed(by: cell.disposeBag)

            cell.tappedCheckMark.rx.event.asDriver().drive(with: self, onNext: { owner, _ in
                IQKeyboardManager.shared.resignFirstResponder()
                let oldTask = owner.tasksViewModel.getTaskTableViewModel(id: viewModel.id).task
                let newViewModel = TaskTableViewCellViewModel(
                    task: oldTask.changeValues(
                        title: oldTask.title, notes: oldTask.notes,
                        isChecked: !oldTask.isChecked, isShowedSubTasks: oldTask.isShowedSubTask))
                owner.tasksViewModel.updateTask(viewModel: newViewModel, beforeId: viewModel.id)
            }).disposed(by: cell.disposeBag)

            cell.infoButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
                IQKeyboardManager.shared.resignFirstResponder()
                let textEditingDidEndViewModel = owner.tasksViewModel.getTaskTableViewModel(id: viewModel.id)
                let nav = UINavigationController(
                    rootViewController: DetailViewController.createInstance(
                        viewModel: DetailViewModel(task: textEditingDidEndViewModel.task)))
                owner.present(nav, animated: true)
            }).disposed(by: cell.disposeBag)

            cell.subTasksButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
                IQKeyboardManager.shared.resignFirstResponder()
                if let index = owner.tasksViewModel.taskTableViewCellViewModelArray.firstIndex(where: { $0.id == viewModel.id}) {
                    let oldViewModel = self.tasksViewModel.getTaskTableViewCellViewModel(index: index)
                    let isShowedSubTasks = !oldViewModel.isShowedSubTasks
                    let oldTask = oldViewModel.task
                    let newViewModel = TaskTableViewCellViewModel(
                        task: oldTask.changeValues(
                            title: oldTask.title, notes: oldTask.notes,
                            isChecked: oldTask.isChecked, isShowedSubTasks: isShowedSubTasks))
                    self.tasksViewModel.updateTask(viewModel: newViewModel, beforeId: oldViewModel.id)

                    if isShowedSubTasks {
                        let subTaskViewModels = newViewModel.subTasks.map { subTask in
                            return TaskTableViewCellViewModel(task: subTask)
                        }
                        owner.tasksViewModel.insertTask(viewModels: subTaskViewModels, index: index + 1)
                    } else {
                        owner.tasksViewModel.removeSubTasks(parentId: viewModel.id)
                    }
                }
            }).disposed(by: cell.disposeBag)
            return cell
        }, titleForHeaderInSection: { dataSource, index in
            return dataSource.sectionModels[index].header
        }, canEditRowAtIndexPath: { _, _ in
            return true
        }, canMoveRowAtIndexPath: { _, _ in
            return true
        })
    }

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = tasksViewModel.taskTableViewCellViewModelArray[indexPath.row]
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {}
}
