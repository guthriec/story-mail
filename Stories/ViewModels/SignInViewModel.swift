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
  private var username: String = ""
  let userSearcher = UserSearcher()
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
  }
  
  func checkUsernameAvailable(name: String?, completion: @escaping (AvailabilityStatus) -> ()) {
    guard let name = name else {
      return
    }
    userSearcher.isUsernameAvailable(name, completion: {status in
        completion(status)
    })
  }
  
  func registerNewUser(name: String?, completion: @escaping (RegistrationStatus) -> ()) {
    guard let name = name else {
      return
    }
    do {
      let localUserInteractor = LocalUserInteractor(managedContext: stateController.managedContext)
      try localUserInteractor.deleteLocalUsersByName(name)
      let newUser = try localUserInteractor.createLocalUser(name: name)
      let authenticator = Authenticator(localUser: newUser)
      try authenticator.register(completion: {(status, message) in
        print("Registration successful?: ", status)
        print("with message: ", message ?? "no message")
        if (status == .Registered) {
          do {
            try localUserInteractor.markAsRegistered(newUser)
          } catch {
            print(error)
            completion(.UnknownError)
          }
          self.setActiveUser(name: name)
        }
        completion(status)
      })
    } catch {
      print("failed to create new local user with error: ", error)
      completion(.UnknownError)
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

enum AvailabilityStatus {
  case Available
  case Unavailable
  case NetworkError
  case UnknownError
}

enum RegistrationStatus {
  case Registered
  case AlreadyRegistered
  case NetworkError
  case UnknownError
}
