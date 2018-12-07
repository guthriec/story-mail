//
//  SignInViewModel.swift
//  Stories
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
    do {
      stateController.deleteLocalUser(name: name)
      let newUser = try stateController.createLocalUser(name: name)
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
    } catch {
      print("failed to create new local user with error: ", error)
      completion(false)
    }
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
  
  let OKAY_CHARACTERS = "abcdefghijklmnopqrstuvwxyz0123456789"
  
  func allCharactersOkay(string: String) -> Bool {
    let cs = NSCharacterSet(charactersIn: OKAY_CHARACTERS).inverted
    let filtered = string.components(separatedBy: cs).joined(separator: "")
    return (string == filtered)
  }

}
