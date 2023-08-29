//
//  Observable.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/7/23.
//

import Foundation

final class ObservableObject<T> {
    var value: T {
        didSet {
            listiner?(value)
        }
    }

    var listiner: ((T) -> Void)?

    init(_ value: T) {
        self.value = value
    }

    func bind(_ listiner: @escaping((T) -> Void)) {
        self.listiner = listiner
        listiner(value)
    }
}
