//
//  DetailTableViewCell.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/06/03.
//

import UIKit

class DetailTableViewCell: UITableViewCell {
    @IBOutlet weak var iconBaseView: UIView!
    @IBOutlet weak var iconView: UIView!
    @IBOutlet weak var textView: UITextView!

    public static let identifier = String(describing: DetailTableViewCell.self)
    public var textEditingDidEnd: ((_ text: String, _ viewModel: TaskTableViewCellViewModel) -> Void)?
    public var lineHeightChanged: (() -> Void)?
    public var tappedCheckMark: ((_ viewModel: TaskTableViewCellViewModel) -> Void)?

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

    private func initialize() {
        initializeLayout()
        selectionStyle = .none
        iconView.isUserInteractionEnabled = false
        textView.returnKeyType = .done
        textView.delegate = self
        iconBaseView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(_tappedCheckMark(_:))))
    }

    private func initializeLayout() {
        iconView.layer.borderColor = R.color.checkIconBorder()?.cgColor
        iconView.layer.borderWidth = 1
        iconView.layer.cornerRadius = iconView.frame.width / 2
        iconView.backgroundColor = R.color.detailAccent()
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
    }

    @objc private func _tappedCheckMark(_ sender: UITapGestureRecognizer) {
        guard let viewModel = taskTableViewCellViewModel else { return }
        tappedCheckMark?(viewModel)
    }
}

extension DetailTableViewCell: UITextViewDelegate {
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
        guard let viewModel = taskTableViewCellViewModel else { return }
        textEditingDidEnd?(textView.text, viewModel)
    }
}
