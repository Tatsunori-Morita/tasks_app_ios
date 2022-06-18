//
//  DetailViewController.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/05/26.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import IQKeyboardManagerSwift

class DetailViewController: UIViewController {
    @IBOutlet weak var titleTextView: PlaceholderTextview!
    @IBOutlet weak var notesTextView: PlaceholderTextview!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addTaskButton: UIButton!

    private static let identifier = String(describing: DetailViewController.self)
    private let disposeBag = DisposeBag()
    private var tableViewConstraintHeight: NSLayoutConstraint?
    private var detailViewModel: DetailViewModel!

    public static func createInstance(viewModel: DetailViewModel) -> DetailViewController {
        let storyboard = UIStoryboard(name: self.identifier, bundle: nil)
        let instance = storyboard.instantiateViewController(withIdentifier: self.identifier) as! DetailViewController
        instance.detailViewModel = viewModel
        return instance
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableViewConstraintHeight?.constant = tableView.contentSize.height
    }

    private func initialize() {
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = R.color.detailBackground()
            appearance.shadowColor = .clear
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = R.color.detailBackground()
            navigationController?.navigationBar.shadowImage = UIImage()
        }

        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        navigationItem.leftBarButtonItem = cancelBarButton
        cancelBarButton.tintColor = R.color.actionBlue()
        cancelBarButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
            owner.dismiss(animated: true)
        }).disposed(by: disposeBag)

        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        navigationItem.rightBarButtonItem = doneBarButton
        doneBarButton.tintColor = R.color.actionBlue()
        doneBarButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
            IQKeyboardManager.shared.resignFirstResponder()
            let subTasks = owner.detailViewModel.detailTableViewCellViewModelArray.map { return $0.task }
            let oldTask = owner.detailViewModel.task

            if owner.detailViewModel.task.isShowedSubTask {
                let newViewModel = TaskTableViewCellViewModel(
                    task: oldTask.changeValues(
                        title: owner.titleTextView.text, notes: owner.notesTextView.text,
                        isChecked: owner.detailViewModel.isChecked, isShowedSubTasks: true, subTasks: subTasks))
                owner.detailViewModel.closedSubTasks(newParentViewModel: newViewModel)
                owner.detailViewModel.openedSubTasks(newParentViewModel: newViewModel)
            } else {
                let newViewModel = TaskTableViewCellViewModel(
                    task: oldTask.changeValues(
                        title: owner.titleTextView.text, notes: owner.notesTextView.text,
                        isChecked: owner.detailViewModel.isChecked, isShowedSubTasks: false, subTasks: subTasks))
                owner.detailViewModel.updateTask(viewModel: newViewModel, beforeId: owner.detailViewModel.id)
            }

            owner.dismiss(animated: true)
        }).disposed(by: disposeBag)

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        tableView.register(
            UINib(nibName: DetailTableViewCell.identifier, bundle: nil),
            forCellReuseIdentifier: DetailTableViewCell.identifier)
        tableViewConstraintHeight = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewConstraintHeight?.isActive = true

        titleTextView.text = detailViewModel.text
        titleTextView.returnKeyType = .done
        titleTextView.delegate = self
        notesTextView.text = detailViewModel.notes
        notesTextView.returnKeyType = .done
        notesTextView.delegate = self

        // Set tableView.
        detailViewModel.detailTableViewSectionViewModelObservable
            .bind(to: tableView.rx.items(dataSource: dataSource()))
            .disposed(by: disposeBag)

        // Delete cell.
        tableView.rx.itemDeleted.asDriver().drive(with: self, onNext: { owner, indexPath in
            let task = Task(id: "", title: "", notes: "", isChecked: false)
            let newViewModel = TaskTableViewCellViewModel(task: task, isNewTask: true)
            let oldViewModel = owner.detailViewModel.getDetailTableViewCellViewModel(index: indexPath.row)
            owner.detailViewModel.updateSubTask(viewModel: newViewModel, beforeId: oldViewModel.taskId)
            self.tableViewConstraintHeight?.constant = self.tableView.contentSize.height
        }).disposed(by: disposeBag)

        // Move cell.
        tableView.rx.itemMoved.asDriver().drive(with: self, onNext: { owner, values in
            let (fromIndexPath, toIndexPath) = values
            guard fromIndexPath != toIndexPath else { return }
            owner.detailViewModel.moveTask(fromIndex: fromIndexPath.row, toIndex: toIndexPath.row)
        }).disposed(by: disposeBag)

        // Add new cell.
        addTaskButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
            IQKeyboardManager.shared.resignFirstResponder()
            DispatchQueue.main.async {
                owner.detailViewModel.addSubTaskCell()
                owner.tableViewConstraintHeight?.constant = owner.tableView.contentSize.height
                let indexPath = IndexPath(row: owner.detailViewModel.detailTableViewCellViewModelArray.count - 1, section: 0)
                owner.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                if let cell = owner.tableView.cellForRow(at: indexPath) as? DetailTableViewCell {
                    cell.textView.becomeFirstResponder()
                }
            }
        }).disposed(by: disposeBag)
    }
}

extension DetailViewController: UITableViewDropDelegate, UITableViewDragDelegate {
    private func dataSource() -> RxTableViewSectionedAnimatedDataSource<TaskTableViewSectionViewModel> {
        return RxTableViewSectionedAnimatedDataSource(animationConfiguration: AnimationConfiguration(insertAnimation: .none, reloadAnimation: .none, deleteAnimation: .none), configureCell: { dataSource, tableView, indexPath, viewModel in
            let cell = tableView.dequeueReusableCell(withIdentifier: DetailTableViewCell.identifier, for: indexPath) as! DetailTableViewCell
            cell.configure(viewModel: viewModel)

            cell.textView.rx.didChange.asDriver().drive(with: self, onNext: { owner, _ in
                tableView.beginUpdates()
                tableView.endUpdates()
            }).disposed(by: cell.disposeBag)

            cell.textView.rx.didEndEditing
                .map { cell.textView.text }
                .filter { $0 != nil }
                .map { $0! }
                .subscribe(onNext: { newText in
                    IQKeyboardManager.shared.resignFirstResponder()
                    let oldTask = viewModel.task
                    let newViewModel = TaskTableViewCellViewModel(task: oldTask.changeValue(title: newText))
                    self.detailViewModel.updateSubTask(viewModel: newViewModel, beforeId: viewModel.taskId)
                    self.tableViewConstraintHeight?.constant = self.tableView.contentSize.height
                }).disposed(by: cell.disposeBag)

            cell.tappedCheckMark.rx.event.asDriver().drive(with: self, onNext: { owner, _ in
                IQKeyboardManager.shared.resignFirstResponder()
                let oldTask = viewModel.task
                let newViewModel = TaskTableViewCellViewModel(task: Task(
                    id: oldTask.id, title: oldTask.title, notes: oldTask.notes,
                    isChecked: !oldTask.isChecked, parentId: oldTask.parentId,
                    subTasks: oldTask.subTasks, isShowedSubTask: oldTask.isShowedSubTask))
                self.detailViewModel.updateSubTask(viewModel: newViewModel, beforeId: viewModel.taskId)
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
        dragItem.localObject = detailViewModel.detailTableViewCellViewModelArray[indexPath.row]
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {}
}

extension DetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
