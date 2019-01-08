//
//  AddContactsViewModel.swift
//  Stories
//
//  Created by Chris on 1/3/19.
//  Copyright © 2019 Sun Canyon. All rights reserved.
//

import Foundation

class AddContactsViewModel {
  private var stateController: StateController!
  private var suggestedContacts: Array<String> {
    didSet {
      onSearchResultChange?()
    }
  }
  
  private var onSearchResultChange: (() -> ())?
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
    self.suggestedContacts = Array<String>()
  }
  
  func setOnSearchResultChange(_ searchResultChangeFn: (() -> ())?) {
    self.onSearchResultChange = searchResultChangeFn
  }
  
  func searchUsersFor(_ username: String, completion: @escaping (Bool) -> ()) {
    let userSearcher = UserSearcher()
    do {
      try userSearcher.findMatchingUsers(username, completion: { results in
        //print("in userSearcher.findMatchingUsers completion with results: ", results)
        self.suggestedContacts = Array<String>()
        for remoteResult in results {
          if !self.suggestedContacts.contains(remoteResult) && remoteResult != self.stateController.activeUsername {
            self.suggestedContacts.append(remoteResult)
          }
        }
        completion(true)
      })
    } catch {
      print("Error in CameraViewModel.searchUsersFor: ", error)
      completion(false)
    }
  }
  
  func numSearchResults() -> Int {
    return suggestedContacts.count
  }
  
  func searchResultAt(_ index: Int) -> String {
    return suggestedContacts[index]
  }

  func isContact(username: String?) -> Bool {
    guard let username = username else {
      return false
    }
    let userInteractor = UserInteractor(managedContext: stateController.managedContext)
    guard userInteractor.fetchExact(username: username) != nil else {
      return false
    }
    return true
  }
  
  func toggleContact(username: String) throws {
    let userInteractor = UserInteractor(managedContext: stateController.managedContext)
    if let existingUser = userInteractor.fetchExact(username: username) {
      print("trying to remove user")
      try userInteractor.removeUser(existingUser)
    } else {
      try _ = userInteractor.fetchOrCreateUser(username: username, firstName: "", lastName: "")
    }
    onSearchResultChange?()
  }
}
