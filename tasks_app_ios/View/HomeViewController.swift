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
        tableView.register(
            UINib(nibName: TaskTableViewCell.identifier, bundle: nil),
            forCellReuseIdentifier: TaskTableViewCell.identifier)
        homeViewModel.tasks.bind(to: tableView.rx.items(dataSource: dataSource()))
            .disposed(by: disposeBag)

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)

        // Delete cell.
        tableView.rx.itemDeleted.asDriver().drive(onNext: { [self] indexPath in
            let task = Task(text: "", isChecked: false)
            let newViewModel = TaskTableViewCellViewModel(task: task, isNewTask: true)
            let oldViewModel = homeViewModel.getTask(index: indexPath.row)
            homeViewModel.updateTasks(
                viewModel: newViewModel, beforeId: oldViewModel.getId)
        }).disposed(by: disposeBag)

        // Add new cell.
        addButton.rx.tap.asDriver().drive(onNext: { [self] _ in
            homeViewModel.addNewTask()
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
         addButton.isHidden = false
         UIView.animate(withDuration: 0.2, animations: { [self] in
             if let unwrappedOffset = tableViewContentOffset {
                 tableView.contentOffset = unwrappedOffset
             }
             tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
         })
     }
}

extension HomeViewController {
    private func dataSource() -> RxTableViewSectionedAnimatedDataSource<TaskTableViewSectionViewModel> {
        return RxTableViewSectionedAnimatedDataSource(animationConfiguration: AnimationConfiguration(insertAnimation: .none, reloadAnimation: .none, deleteAnimation: .none), configureCell: { dataSource, tableView, indexPath, viewModel in
            let cell = tableView.dequeueReusableCell(withIdentifier: TaskTableViewCell.identifier, for: indexPath) as! TaskTableViewCell
            cell.configure(viewModel: viewModel)

            cell.lineHeightChanged = {
                tableView.beginUpdates()
                tableView.endUpdates()
            }

            cell.textEditingDidEnd = { newText, viewModel in
                let task = Task(text: newText, isChecked: viewModel.isChecked)
                let newViewModel = TaskTableViewCellViewModel(task: task)
                self.homeViewModel.updateTasks(viewModel: newViewModel, beforeId: viewModel.getId)
            }

            cell.tappedCheckMark = { viewModel in
                let task = Task(text: viewModel.text, isChecked: !viewModel.isChecked)
                let newViewModel = TaskTableViewCellViewModel(task: task)
                self.homeViewModel.updateTasks(viewModel: newViewModel, beforeId: viewModel.getId)
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
}
