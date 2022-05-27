//
//  Task.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/14.
//

import Foundation

struct Task: Codable {
    private let _id: String
    private let _title: String
    private let _notes: String
    private let _isChecked: Bool
    private let _parentId: String
    private let _order: Double

    init(id: String = "", title: String, notes: String = "", isChecked: Bool, parentId: String = "", order: Double = 0.0) {
        _id = id.isEmpty ? UUID().uuidString : id
        _title = title
        _notes = notes
        _isChecked = isChecked
        _parentId = parentId
        _order = order
    }

    public var getId: String {
        _id
    }

    public var getTitle: String {
        _title
    }

    public var getNotes: String {
        _notes
    }

    public var getIsChecked: Bool {
        _isChecked
    }

    public var getParentId: String {
        _parentId
    }

    public var getOrder: Double {
        _order
    }
}
