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
        tableView.estimatedRowHeight = 48
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(
            UINib(nibName: TaskTableViewCell.identifier, bundle: nil),
            forCellReuseIdentifier: TaskTableViewCell.identifier)
        homeViewModel.tasks.bind(to: tableView.rx.items(dataSource: dataSource()))
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .map { _ in true }
            .subscribe(addButton.rx.isHidden)
            .disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .map { _ in false }
            .subscribe(addButton.rx.isHidden)
            .disposed(by: disposeBag)

        // Delete cell.
        tableView.rx.itemDeleted.asDriver().drive(onNext: { [self] indexPath in
            homeViewModel.updateItems(
                viewModel: TaskTableViewCellViewModel(text: "", isChecked: false),
                index: indexPath)
        }).disposed(by: disposeBag)

        // Add new cell.
        addButton.rx.tap.asDriver().drive(onNext: { [self] _ in
            homeViewModel.addNewItem()
        }).disposed(by: disposeBag)
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

            cell.textEditingDidEnd = { text in
                let newViewModel = TaskTableViewCellViewModel(text: text, isChecked: viewModel.isChecked)
                self.homeViewModel.updateItems(viewModel: newViewModel, index: indexPath)
            }

            cell.tappedCheckMark = { viewModel in
                let newViewModel = TaskTableViewCellViewModel(text: viewModel.text, isChecked: !viewModel.isChecked)
                self.homeViewModel.updateItems(viewModel: newViewModel, index: indexPath)
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
