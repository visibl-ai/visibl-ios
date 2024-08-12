//
//  UIMenu+lazyMenuItems.swift
//  visibl
//
//

import UIKit

extension UIMenu {
    /// rebuilds menu items on every access
    static func lazyMenuItems(builder: @escaping () -> [UIMenuElement]) -> UIMenu {
        return UIMenu(options: .displayInline, children: [
            UIDeferredMenuElement.uncached { completion in
                let items = builder()
                completion(items)
            }
        ])
    }
}
