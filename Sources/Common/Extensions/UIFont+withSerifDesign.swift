//
//  UIFont+withSerifDesign.swift
//  visibl
//
//

import UIKit

extension UIFont {
    func withSerifDesign() -> UIFont {
        let newDescriptor = fontDescriptor.withDesign(.serif) ?? fontDescriptor
        return UIFont(descriptor: newDescriptor, size: 0)
    }
}
