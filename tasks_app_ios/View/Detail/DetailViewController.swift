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

class DetailViewController: UIViewController {
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var notesTextView: UITextView!
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
            appearance.backgroundColor = R.color.background()
            appearance.shadowColor = .clear
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = R.color.background()
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
            let children = owner.detailViewModel.detailTableViewCellViewModelArray.map { return $0.task }
            let task = Task(title: owner.titleTextView.text,
                            notes: owner.notesTextView.text,
                            isChecked: owner.detailViewModel.isChecked,
                            children: children)
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
            UINib(nibName: TaskTableViewCell.identifier, bundle: nil),
            forCellReuseIdentifier: TaskTableViewCell.identifier)
        tableViewConstraintHeight = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewConstraintHeight?.isActive = true

        titleTextView.text = detailViewModel.text
        notesTextView.text = detailViewModel.notes

        // Set tableView.
        detailViewModel.detailTableViewSectionViewModelObservable
            .bind(to: tableView.rx.items(dataSource: dataSource()))
            .disposed(by: disposeBag)

        // Add new cell.
        addTaskButton.rx.tap.asDriver().drive(with: self, onNext: { owner, _ in
            DispatchQueue.main.async {
                owner.detailViewModel.addSubTaskCell()
                owner.tableViewConstraintHeight?.constant = owner.tableView.contentSize.height
                let indexPath = IndexPath(row: owner.detailViewModel.detailTableViewCellViewModelArray.count - 1, section: 0)
                owner.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                if let cell = owner.tableView.cellForRow(at: indexPath) as? TaskTableViewCell {
                    cell.textView.becomeFirstResponder()
                }
            }
        }).disposed(by: disposeBag)
    }
}

extension DetailViewController: UITableViewDropDelegate, UITableViewDragDelegate {
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
                let task = Task(title: newText, notes: viewModel.note, isChecked: viewModel.isChecked, parentId: viewModel.id)
                let newViewModel = TaskTableViewCellViewModel(task: task)
                self.detailViewModel.updateSubTask(viewModel: newViewModel, beforeId: viewModel.id)
            }

            cell.tappedCheckMark = { [weak self] viewModel in
                guard let self = self else { return }
                let task = Task(title: viewModel.title, notes: viewModel.note, isChecked: !viewModel.isChecked, parentId: viewModel.id)
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
//        dragItem.localObject = tasksViewModel.taskTableViewCellViewModelArray[indexPath.row]
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {}
}
