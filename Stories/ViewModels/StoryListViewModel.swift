//
//  StoryListViewModel.swift
//  Stories
//
//  Created by Chris on 10/23/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class StoryListViewModel {
  var stateController: StateController!
  
  private var onStorySyncStartFn: (() -> ())?
  private var onStorySyncCompleteFn: ((Bool) -> ())?
  
  private var pollTimer: DispatchSourceTimer
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
    let queue = DispatchQueue.global(qos: .background)
    self.pollTimer = DispatchSource.makeTimerSource(queue: queue)
    self.pollTimer.schedule(deadline: .now(), repeating: .seconds(60), leeway: .seconds(10))
    self.pollTimer.setEventHandler(handler: {
      //print("in timer event handler")
      self.refreshStories()
    })
    self.pollTimer.resume()
  }
  
  func onStorySyncStart() {
    onStorySyncStartFn?()
  }
  
  func onStorySyncComplete(success: Bool) {
    onStorySyncCompleteFn?(success)
  }
  
  func setOnStorySyncStart(_ storySyncStartFn: (() -> ())?) {
    self.onStorySyncStartFn = storySyncStartFn
  }
  
  func setOnStorySyncComplete(_ storySyncCompleteFn: ((Bool) -> ())?) {
    self.onStorySyncCompleteFn = storySyncCompleteFn
  }
  
  func refreshStories() {
    self.onStorySyncStart()
    self.stateController.synchronizeStoriesForActiveUser(completion: {success in
      //print("in fetchStoriesForactiveUser Completion in SLVM.refreshStories")
      DispatchQueue.main.async {
        self.onStorySyncComplete(success: success)
      }
    })
  }
  
  func newTableViewModelFor(storyList: StoryList) -> StoryListTableViewModel {
    return StoryListTableViewModel(stateController: stateController, storyList: storyList)
  }
  
  func newCameraViewModel() -> CameraViewModel {
    return CameraViewModel(stateController)
  }
  
  func newArchiveViewModel() -> StoryListViewModel {
    return StoryListViewModel(self.stateController)
  }
  
  func newInboxTableViewModel() -> StoryListTableViewModel {
    return newTableViewModelFor(storyList: stateController.inboxStories)
  }
  
  func newArchiveTableViewModel() -> StoryListTableViewModel {
    return newTableViewModelFor(storyList: stateController.archivedStories)
  }
  
  func newProfileViewModel() -> ProfileViewModel {
    return ProfileViewModel(stateController)
  }
  
  func newStoryViewModel() -> StoryViewModel {
    return StoryViewModel(stateController)
  }
}
