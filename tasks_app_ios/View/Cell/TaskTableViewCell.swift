//
//  TaskTableViewCell.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/07.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    @IBOutlet weak var iconBaseView: UIView!
    @IBOutlet weak var iconView: UIView!
    @IBOutlet weak var textView: UITextView!

    public static let identifier = String(describing: TaskTableViewCell.self)
    public var textEditingDidEnd: ((_ text: String, _ isChecked: Bool) -> Void)?
    public var lineHeightChanged: (() -> Void)?
    public var tappedCheckMark: ((TaskTableViewCellViewModel) -> Void)?

    private var taskTableViewCellViewModel: TaskTableViewCellViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }

    private func initialize() {
        initializeLayout()
        selectionStyle = .none
        iconView.isUserInteractionEnabled = false
        textView.returnKeyType = .done
        textView.delegate = self
        iconBaseView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapCheckMark(_:))))
    }

    private func initializeLayout() {
        iconView.layer.borderColor = UIColor.init(named: "checkIconBorder")?.cgColor
        iconView.layer.borderWidth = 1
        iconView.layer.cornerRadius = iconView.frame.width / 2
        iconView.backgroundColor = UIColor.init(named: "background")
    }

    public func configure(viewModel: TaskTableViewCellViewModel) {
        initializeLayout()
        taskTableViewCellViewModel = viewModel
        textView.text = viewModel.text

        if viewModel.isChecked {
            iconView.backgroundColor = UIColor.init(named: "checked")
            iconView.layer.borderWidth = 0
        }

        DispatchQueue.main.async {
            if viewModel.isNewTask {
                self.textView.becomeFirstResponder()
            }
        }
    }

    @objc private func tapCheckMark(_ sender: UITapGestureRecognizer) {
        guard let vm = taskTableViewCellViewModel else { return }
        tappedCheckMark?(vm)
    }
}

extension TaskTableViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        lineHeightChanged?()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let vm = taskTableViewCellViewModel else { return }
        textEditingDidEnd?(textView.text, vm.isChecked)
    }
}
