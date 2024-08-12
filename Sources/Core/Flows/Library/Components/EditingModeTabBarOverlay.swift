//
//  EditingModeTabBarOverlay.swift
//  visibl
//
//

import UIKit

class EditingModeTabBarOverlay: UIView {
    let deleteButton = UIButton(type: .system)
    let addToButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        addSubview(addToButton)
        addSubview(deleteButton)
        
        addToButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addToButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            addToButton.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            addToButton.heightAnchor.constraint(equalToConstant: 44),
            
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            deleteButton.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            deleteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        configureButton(addToButton, title: "Add to...", imageName: "text.badge.plus")
        configureButton(deleteButton, imageName: "trash")
        
        updateButtonStates(isEnabled: false)
    }
    
    func updateButtonStates(isEnabled: Bool) {
        addToButton.isEnabled = isEnabled
        deleteButton.isEnabled = isEnabled
    }
    
    private func configureButton(_ button: UIButton, title: String? = "", imageName: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: imageName)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6
        configuration.contentInsets = .zero
        configuration.titlePadding = 0
        button.configuration = configuration
        button.tintColor = .label
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        button.backgroundColor = .clear
    }
}
