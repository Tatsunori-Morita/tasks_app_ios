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
    private var selectedDragRowIndex = 0

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
            let newTask = oldViewModel.task.getRemovingTask()
            let newViewModel = TaskTableViewCellViewModel(task: newTask, isNewTask: true)
            owner.tasksViewModel.removeTask(viewModel: newViewModel)
        }).disposed(by: disposeBag)

        // Move cell.
        tableView.rx.itemMoved.asDriver().drive(with: self, onNext: { owner, values in
            let (fromIndexPath, toIndexPath) = values
            guard fromIndexPath.row != toIndexPath.row else {
                return
            }
            owner.tasksViewModel.moveTask(fromIndex: fromIndexPath.row, toIndex: toIndexPath.row)
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
                    self.tasksViewModel.changeTitle(viewModel: viewModel, text: newText)
                }).disposed(by: cell.disposeBag)

            cell.tappedCheckMark.rx.event.asDriver().drive(with: self, onNext: { owner, _ in
                IQKeyboardManager.shared.resignFirstResponder()
                owner.tasksViewModel.changeCheckMark(viewModel: viewModel)
            }).disposed(by: cell.disposeBag)

            cell.infoButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
                IQKeyboardManager.shared.resignFirstResponder()
                let oldViewMolde = owner.tasksViewModel.getTaskTableViewModel(id: viewModel.taskId)
                let newSubTasks = oldViewMolde.isShowedSubTasks ?
                owner.tasksViewModel.getOpenedSubTasks(parentId: viewModel.taskId) : oldViewMolde.subTasks
                let oldTask = oldViewMolde.task
                let newParentTask = oldTask.changeValue(isShowedSubTasks: oldViewMolde.isShowedSubTasks, subTasks: newSubTasks)
                let nav = UINavigationController(
                    rootViewController: DetailViewController.createInstance(
                        viewModel: DetailViewModel(task: newParentTask)))
                owner.present(nav, animated: true)
            }).disposed(by: cell.disposeBag)

            cell.subTasksButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
                IQKeyboardManager.shared.resignFirstResponder()
                let isShowedSubTasks = !viewModel.isShowedSubTasks
                if isShowedSubTasks {
                    owner.tasksViewModel.openSubTasks(viewModel: viewModel)
                } else {
                    owner.tasksViewModel.closeSubTasks(viewModel: viewModel)
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
        let viewModel = tasksViewModel.getTaskTableViewCellViewModel(index: indexPath.row)

        if viewModel.isShowedSubTasks {
            tasksViewModel.closeSubTasks(viewModel: viewModel)
        }
        selectedDragRowIndex = indexPath.row
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = tasksViewModel.taskTableViewCellViewModelArray[indexPath.row]
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {}

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

        guard let row = destinationIndexPath?.row, row < tasksViewModel.taskTableViewCellViewModelArray.count else {
            return UITableViewDropProposal(operation: .cancel)
        }

        let fromViewModel = tasksViewModel.getTaskTableViewCellViewModel(index: selectedDragRowIndex)
        let toViewModel = tasksViewModel.getTaskTableViewCellViewModel(index: row)

        if fromViewModel.hasSubTasks && toViewModel.hasSubTasks || !toViewModel.parentId.isEmpty {
            return UITableViewDropProposal(operation: .cancel)
        }
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}
