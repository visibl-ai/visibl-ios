//
//  SettingsViewModel.swift
//  visibl
//
//

import Foundation
import Combine
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var user: CurrentUserModel?
    @Published var axxUser: AAXUserModel?
    var authService = AuthService.shared
    var aaxManager: AAXManager
    
    enum Events {
        case showAuth
        case showAAXAuth
    }
    
    var cancellables = Set<AnyCancellable>()
    let eventSender = PassthroughSubject<SettingsViewModel.Events, Never>()
    
    init(aaxManager: AAXManager) {
        self.aaxManager = aaxManager
        
        authService.$user
            .sink { [weak self] user in
                self?.user = user
                if user == nil {
                    // If authService.user becomes nil, set aaxManager.axxUser to nil
                    self?.aaxManager.axxUser = nil
                }
            }
            .store(in: &cancellables)
        
        aaxManager.$axxUser
            .assign(to: \.axxUser, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return version
    }
}
