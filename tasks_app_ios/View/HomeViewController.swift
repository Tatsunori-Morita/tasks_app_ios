//
//  HomeViewController.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class HomeViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!

    private static let identifier = String(describing: HomeViewController.self)
    private let disposeBag = DisposeBag()
    private let homeViewModel = HomeViewModel()
    private var tableViewContentOffset: CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }

    public static func createInstance() -> HomeViewController {
        let storyboard = UIStoryboard(name: self.identifier, bundle: nil)
        let instance = storyboard.instantiateViewController(withIdentifier: self.identifier) as! HomeViewController
        return instance
    }

    private func initialize() {
        addButton.setTitle("", for: .normal)
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        tableView.register(
            UINib(nibName: TaskTableViewCell.identifier, bundle: nil),
            forCellReuseIdentifier: TaskTableViewCell.identifier)

        // Set tableView.
        homeViewModel.taskTableViewSectionViewModelBehaviorRelay
            .bind(to: tableView.rx.items(dataSource: dataSource()))
            .disposed(by: disposeBag)

        // Delete cell.
        tableView.rx.itemDeleted.asDriver().drive(with: self, onNext: { owner, indexPath in
            let task = Task(text: "", isChecked: false)
            let newViewModel = TaskTableViewCellViewModel(task: task, isNewTask: true)
            let oldViewModel = owner.homeViewModel.getTaskTableViewCellViewModel(index: indexPath.row)
            owner.homeViewModel.updateTasks(
                viewModel: newViewModel, beforeId: oldViewModel.getId)
        }).disposed(by: disposeBag)

        // Move cell.
        tableView.rx.itemMoved.asDriver().drive(with: self, onNext: { owner, values in
            let (fromIndexPath, toIndexPath) = values
            guard fromIndexPath != toIndexPath else { return }
            let fromIndexPathViewModel = owner.homeViewModel.getTaskTableViewCellViewModel(index: fromIndexPath.row)
            owner.homeViewModel.updateTasks(
                viewModel: fromIndexPathViewModel,
                fromIndex: fromIndexPath.row, toIndex: toIndexPath.row)
        }).disposed(by: disposeBag)

        // Add new cell.
        addButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
            owner.homeViewModel.addNewTask()
            let indexPath = IndexPath(row: owner.homeViewModel.taskTableViewCellViewModelArray.count - 1, section: 0)
            owner.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            if let cell = owner.tableView.cellForRow(at: indexPath) as? TaskTableViewCell {
                cell.textView.becomeFirstResponder()
            }
        }).disposed(by: disposeBag)
    }
}

extension HomeViewController {
    @objc private func keyboardWillShow(notification: NSNotification) {
        addButton.isHidden = true
        tableViewContentOffset = tableView.contentOffset
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
     }

     @objc private func keyboardWillHide(notification: NSNotification) {
         DispatchQueue.main.async { [weak self] in
             guard let self = self else { return }
             self.addButton.isHidden = false
             UIView.animate(withDuration: 0.2, animations: {
                 if let unwrappedOffset = self.tableViewContentOffset {
                     self.tableView.contentOffset = unwrappedOffset
                 }
                 self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
             })
         }
     }
}

extension HomeViewController: UITableViewDropDelegate, UITableViewDragDelegate {
    private func dataSource() -> RxTableViewSectionedAnimatedDataSource<TaskTableViewSectionViewModel> {
        return RxTableViewSectionedAnimatedDataSource(animationConfiguration: AnimationConfiguration(insertAnimation: .none, reloadAnimation: .none, deleteAnimation: .none), configureCell: { dataSource, tableView, indexPath, viewModel in
            let cell = tableView.dequeueReusableCell(withIdentifier: TaskTableViewCell.identifier, for: indexPath) as! TaskTableViewCell
            cell.configure(viewModel: viewModel)

            cell.lineHeightChanged = {
                tableView.beginUpdates()
                tableView.endUpdates()
            }

            cell.textEditingDidEnd = { [weak self] newText, viewModel in
                guard let self = self else { return }
                let task = Task(text: newText, isChecked: viewModel.isChecked)
                let newViewModel = TaskTableViewCellViewModel(task: task)
                self.homeViewModel.updateTasks(viewModel: newViewModel, beforeId: viewModel.getId)
            }

            cell.tappedCheckMark = { [weak self] viewModel in
                guard let self = self else { return }
                let task = Task(text: viewModel.text, isChecked: !viewModel.isChecked)
                let newViewModel = TaskTableViewCellViewModel(task: task)
                self.homeViewModel.updateTasks(viewModel: newViewModel, beforeId: viewModel.getId)
            }

            cell.tappedInfoButton = {

            }
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
        dragItem.localObject = homeViewModel.taskTableViewCellViewModelArray[indexPath.row]
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {}
}
