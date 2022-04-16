//
//  Task.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/14.
//

struct Task: Codable {
    private var _text: String
    private var _isChecked: Bool

    init(text: String, isChecked: Bool) {
        _text = text
        _isChecked = isChecked
    }

    public var getText: String {
        _text
    }

    public var getIsChecked: Bool {
        _isChecked
    }
}
