//
//  TaskTableViewSectionViewModel.swift
//  tasks_app_ios
//
//  Created by Tatsunori on 2022/04/16.
//

import RxDataSources

struct TaskTableViewSectionViewModel {
    var id = UUID().uuidString
    var header: String
    var items: [Item]
}

extension TaskTableViewSectionViewModel: AnimatableSectionModelType {
    typealias Item = TaskTableViewCellViewModel

    var identity: String {
        return id
    }

    init(original: TaskTableViewSectionViewModel, items: [Item]) {
        self = original
        self.items = items
    }
}
