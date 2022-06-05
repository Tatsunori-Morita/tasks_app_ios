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
            let children = owner.detailViewModel.detailTableViewCellViewModelArray.map { return $0.task }
            let task = Task(title: owner.titleTextView.text,
                            notes: owner.notesTextView.text,
                            isChecked: owner.detailViewModel.isChecked,
                            subTasks: children)
            let newViewModel = TaskTableViewCellViewModel(task: task)
            owner.detailViewModel.updateTask(viewModel: newViewModel, beforeId: owner.detailViewModel.id)
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
            let task = Task(title: "", notes: "", isChecked: false)
            let newViewModel = TaskTableViewCellViewModel(task: task, isNewTask: true)
            let oldViewModel = owner.detailViewModel.getDetailTableViewCellViewModel(index: indexPath.row)
            owner.detailViewModel.updateSubTask(
                viewModel: newViewModel, beforeId: oldViewModel.id)
            self.tableViewConstraintHeight?.constant = self.tableView.contentSize.height
        }).disposed(by: disposeBag)

        // Move cell.
        tableView.rx.itemMoved.asDriver().drive(with: self, onNext: { owner, values in
            let (fromIndexPath, toIndexPath) = values
            guard fromIndexPath != toIndexPath else { return }
            let fromIndexPathViewModel = owner.detailViewModel.getDetailTableViewCellViewModel(index: fromIndexPath.row)
            owner.detailViewModel.moveTask(fromViewModel: fromIndexPathViewModel, toIndex: toIndexPath.row)
        }).disposed(by: disposeBag)

        // Add new cell.
        addTaskButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
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

            cell.lineHeightChanged = {
                tableView.beginUpdates()
                tableView.endUpdates()
            }

            cell.textEditingDidEnd = { [weak self] newText, viewModel in
                guard let self = self else { return }
                let task = Task(title: newText, notes: viewModel.notes, isChecked: viewModel.isChecked, parentId: viewModel.id)
                let newViewModel = TaskTableViewCellViewModel(task: task)
                self.detailViewModel.updateSubTask(viewModel: newViewModel, beforeId: viewModel.id)
                self.tableViewConstraintHeight?.constant = self.tableView.contentSize.height
            }

            cell.tappedCheckMark = { [weak self] viewModel in
                guard let self = self else { return }
                let task = Task(title: viewModel.title, notes: viewModel.notes,
                                isChecked: !viewModel.isChecked, parentId: viewModel.id)
                let newViewModel = TaskTableViewCellViewModel(task: task)
                self.detailViewModel.updateSubTask(viewModel: newViewModel, beforeId: viewModel.id)
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
