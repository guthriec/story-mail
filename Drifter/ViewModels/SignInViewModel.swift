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
  
  func setActiveUser(name: String?) {
    guard let userName = name else {
      return
    }
    stateController.setActiveUser(name: userName)
  }
  
  func newInboxViewModel() -> StoryListViewModel {
    return StoryListViewModel(self.stateController)
  }
}
