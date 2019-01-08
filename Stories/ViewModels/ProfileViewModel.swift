//
//  ProfileViewModel.swift
//  Stories
//
//  Created by Chris on 11/5/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class ProfileViewModel {
  private var stateController: StateController!
  var matchingContacts: Array<String>
  
  func setOnActiveUserChange(_ onActiveUserChangeFn: (() -> ())?) {
    stateController.onActiveUserChange = onActiveUserChangeFn
  }
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
    matchingContacts = Array<String>()
    fetchContactsWithQuery(username: "")
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
  
  func deleteActiveUser() throws {
    try stateController.deleteActiveUser()
  }
  
  func fetchContactsWithQuery(username: String) {
    let userInteractor = UserInteractor(managedContext: stateController.managedContext)
    matchingContacts = userInteractor.fetchUsernamesMatchingPartial(username: username)
                                     .filter {$0 != activeUsername}
  }
  
  func numContacts() -> Int {
    return matchingContacts.count
  }
  
  func contactAt(_ position: Int) -> String? {
    if position < matchingContacts.count {
      return matchingContacts[position]
    } else {
      return nil
    }
  }
  
  func newAddContactsViewModel() -> AddContactsViewModel {
    return AddContactsViewModel(stateController)
  }
}
