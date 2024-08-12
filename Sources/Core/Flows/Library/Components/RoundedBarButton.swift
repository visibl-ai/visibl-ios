//
//  RoundedBarButton.swift
//  visibl
//
//

import UIKit

class CustomRoundedButton: UIButton {
    
    init(systemName: String) {
        super.init(frame: .zero)
        setupButton(systemName: systemName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton(systemName: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium, scale: .medium)
        let image = UIImage(systemName: systemName, withConfiguration: config)
        setImage(image, for: .normal)
        frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        tintColor = .label
        backgroundColor = .systemGray4
        layer.cornerRadius = 12
    }
    
    func asBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(customView: self)
    }
}
