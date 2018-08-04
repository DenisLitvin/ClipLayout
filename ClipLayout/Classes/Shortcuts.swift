//
//  Shortcuts.swift
//  ClipLayout
//
//  Created by Denis Litvin on 04.08.2018.
//

import Foundation

extension UIEdgeInsets: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        let val = CGFloat(value)
        self.init(top: val, left: val, bottom: val, right: val)
    }
}

