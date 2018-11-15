//
//  SignInViewModel.swift
//  Drifter
//
//  Created by Chris on 11/5/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class SignInViewModel {
  private var stateController: StateController!
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
  }
  
  func registerNewUser(name: String?, completion: @escaping (Bool) -> ()) {
    guard let name = name else {
      return
    }
    let newUser = stateController.createLocalUser(name: name)
    let authenticator = Authenticator(localUser: newUser)
    authenticator.register(completion: {(success, message) in
      print("Registration successful?: ", success)
      print("with message: ", message ?? "no message")
      if (success) {
        self.stateController.saveLocalUser(newUser)
        self.setActiveUser(name: name)
      }
      completion(success)
    })
  }
  
  func setActiveUser(name: String?) {
    guard let username = name else {
      return
    }
    stateController.setActiveUser(name: username)
  }
  
  func newInboxViewModel() -> StoryListViewModel {
    return StoryListViewModel(self.stateController)
  }
  
  func localUsernames() -> Array<String>? {
    return stateController.localUserNames
  }
}
