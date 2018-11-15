//
//  ProfileViewModel.swift
//  Drifter
//
//  Created by Chris on 11/5/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class ProfileViewModel {
  private var stateController: StateController!
  
  func setOnActiveUserChange(_ onActiveUserChangeFn: (() -> ())?) {
    stateController.onActiveUserChange = onActiveUserChangeFn
  }
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
  }
  
  var activeUsername: String? {
    return stateController.activeUsername
  }
  
  var localUsernames: Array<String>? {
    return stateController.localUserNames
  }
  
  func changeActiveUsername(name: String) {
    stateController.setActiveUser(name: name)
  }
  
  func newSignInViewModel() -> SignInViewModel {
    return SignInViewModel(stateController)
  }
  
  func deleteActiveUser() {
    stateController.deleteActiveUser()
  }
  
}
