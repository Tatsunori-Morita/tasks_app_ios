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
    @IBOutlet weak var tableView: UITableView!

    private static let identifier = String(describing: DetailViewController.self)
    private let disposeBag = DisposeBag()
    private var tableViewConstraintHeight: NSLayoutConstraint?

    public static func createInstance() -> DetailViewController {
        let storyboard = UIStoryboard(name: self.identifier, bundle: nil)
        let instance = storyboard.instantiateViewController(withIdentifier: self.identifier) as! DetailViewController
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

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: nil)
        navigationItem.leftBarButtonItem?.tintColor = R.color.actionBlue()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
        navigationItem.rightBarButtonItem?.tintColor = R.color.actionBlue()

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
//        tableView.register(
//            UINib(nibName: TaskTableViewCell.identifier, bundle: nil),
//            forCellReuseIdentifier: TaskTableViewCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableViewConstraintHeight = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewConstraintHeight?.isActive = true

        let items = Observable<[String]>.just(["test1", "test2", "test3", "test4"])
        // Set tableView.
        items.bind(to: tableView.rx.items(cellIdentifier: "cell")) { row, item, cell in
            cell.textLabel?.text = item
        }.disposed(by: disposeBag)
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
//                let task = Task(text: newText, isChecked: viewModel.isChecked)
//                let newViewModel = TaskTableViewCellViewModel(task: task)
//                self.tasksViewModel.updateTasks(viewModel: newViewModel, beforeId: viewModel.getId)
            }

            cell.tappedCheckMark = { [weak self] viewModel in
                guard let self = self else { return }
//                let task = Task(text: viewModel.text, isChecked: !viewModel.isChecked)
//                let newViewModel = TaskTableViewCellViewModel(task: task)
//                self.tasksViewModel.updateTasks(viewModel: newViewModel, beforeId: viewModel.getId)
            }

            cell.tappedInfoButton = { [unowned self] in
//                let nav = UINavigationController(rootViewController: DetailViewController.createInstance())
//                self.present(nav, animated: true)
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
