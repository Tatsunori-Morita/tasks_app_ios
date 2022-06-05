//
//  Task.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/14.
//

import Foundation

class Task: Codable {
    private let _id: String
    private let _title: String
    private let _notes: String
    private let _isChecked: Bool
    private let _parentId: String
    private let _subTasks: [Task]

    init(id: String = "", title: String, notes: String, isChecked: Bool, parentId: String = "", subTasks: [Task] = []) {
        _id = id.isEmpty ? UUID().uuidString : id
        _title = title
        _notes = notes
        _isChecked = isChecked
        _parentId = parentId
        _subTasks = subTasks
    }

    public var id: String {
        _id
    }

    public var title: String {
        _title
    }

    public var notes: String {
        _notes
    }

    public var isChecked: Bool {
        _isChecked
    }

    public var parentId: String {
        _parentId
    }

    public var subTasks: [Task] {
        _subTasks
    }
}
