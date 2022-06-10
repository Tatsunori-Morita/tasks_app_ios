//
//  TaskTableViewCell.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

import UIKit
import RxSwift

class TaskTableViewCell: UITableViewCell {
    @IBOutlet weak var iconBaseView: UIView!
    @IBOutlet weak var iconView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var subTasksButton: UIButton!
    @IBOutlet weak var stackViewLeftConstraint: NSLayoutConstraint!

    public static let identifier = String(describing: TaskTableViewCell.self)
    public var textEditingDidEnd: ((_ text: String) -> Void)?
    public let tappedCheckMark = UITapGestureRecognizer()
    public var disposeBag = DisposeBag()

    private var taskTableViewCellViewModel: TaskTableViewCellViewModel?

    private let normalTextAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16),
        .foregroundColor: R.color.text()!
    ]

    private let checkedTextAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16),
        .foregroundColor: R.color.checkedText()!
    ]

    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    private func initialize() {
        initializeLayout()
        selectionStyle = .none
        iconView.isUserInteractionEnabled = false
        textView.returnKeyType = .done
        textView.delegate = self
        iconBaseView.addGestureRecognizer(tappedCheckMark)
    }

    private func initializeLayout() {
        stackViewLeftConstraint.constant = 14
        iconView.layer.borderColor = R.color.checkIconBorder()?.cgColor
        iconView.layer.borderWidth = 1
        iconView.layer.cornerRadius = iconView.frame.width / 2
        iconView.backgroundColor = R.color.background()
        infoButton.isHidden = true
        subTasksButton.isHidden = true
        subTasksButton.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
        textView.isEditable = true
        textView.attributedText = NSMutableAttributedString(string: textView.text!, attributes: normalTextAttributes)
    }

    public func configure(viewModel: TaskTableViewCellViewModel) {
        initializeLayout()
        taskTableViewCellViewModel = viewModel
        textView.text = viewModel.title

        if viewModel.isChecked {
            iconView.backgroundColor = R.color.checked()
            iconView.layer.borderWidth = 0
            textView.isEditable = false

            let attr =  NSMutableAttributedString(string: textView.text!, attributes: checkedTextAttributes)
            attr.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, attr.length))
            textView.attributedText = attr
        }

        if viewModel.hasSubTasks {
            subTasksButton.isHidden = false
            if viewModel.isShowedSubTasks {
                subTasksButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            }
        }

        if viewModel.isChild {
            stackViewLeftConstraint.constant = 50
        }
    }
}

extension TaskTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
