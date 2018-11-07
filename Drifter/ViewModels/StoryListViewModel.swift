//
//  StoryListViewModel.swift
//  Drifter
//
//  Created by Chris on 10/23/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class StoryListViewModel {
  var stateController: StateController!
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
  }
  
  func newTableViewModelFromManaged(storyList: ManagedStoryList) -> StoryListTableViewModel {
    return StoryListTableViewModel(stateController: stateController, managedStoryList: storyList)
  }
  
  func newCameraViewModel() -> CameraViewModel {
    return CameraViewModel(stateController)
  }
  
  func newArchiveViewModel() -> StoryListViewModel {
    return StoryListViewModel(self.stateController)
  }
  
  func newInboxTableViewModel() -> StoryListTableViewModel {
    return newTableViewModelFromManaged(storyList: stateController.managedInboxStories)
  }
  
  func newArchiveTableViewModel() -> StoryListTableViewModel {
    return newTableViewModelFromManaged(storyList: stateController.archivedStories)
  }
  
  func newProfileViewModel() -> ProfileViewModel {
    return ProfileViewModel(stateController)
  }
}
