//
//  StoryListTableViewModel.swift
//  Stories
//
//  Created by Chris on 10/23/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation
import UIKit


class StoryListTableViewModel {
  var stateController: StateController
  var managedStoryList: ManagedStoryList
  
  var storyScrollMap = [String : Int]()
  
  init(stateController: StateController!, managedStoryList: ManagedStoryList) {
    self.stateController = stateController
    self.managedStoryList = managedStoryList
  }
  
  func setOnStoryListChange(_ onStoryChange: (() -> ())?) {
    self.managedStoryList.add(onStoryListChangeFn: onStoryChange)
  }
  
  func numManagedStories() -> Int {
    return self.managedStoryList.managedStories.count
  }
  
  func numPagesInManagedStoryAt(index i: Int) -> Int {
    if (self.managedStoryList.managedStories.indices.contains(i)) {
      guard let pageSet = self.managedStoryList.managedStories[i].pages else {
        return 0
      }
      return pageSet.count
    } else {
      return 0
    }
  }
  
  func managedStoryIdAt(index i: Int) -> String {
    return self.managedStoryList.managedStories[i].id!
  }
  
  func nthPageInManagedStoryAt(storyIndex i: Int, pageIndex n: Int) -> PageData? {
    guard let pageSet = self.managedStoryList.managedStories[i].pages else {
      print("couldn't get pageset")
      return nil
    }
    return PageData(fromManaged: pageSet[n] as! PageMO, activeUsername: stateController.activeUsername)
  }
    
  func setReplyId(storyId id: String) -> Void {
    stateController.replyingToStoryId = id
  }
  
  func deleteStory(byId id: String?) {
    guard let storyId = id else {
      return
    }
    managedStoryList.removeStoryWith(id: storyId)
    stateController.deleteStory(id: storyId)
  }
  
  func archiveStory(byId id: String?) {
    guard let storyId = id else {
      return
    }
    stateController.archiveStory(id: storyId)
  }
  
  func unArchiveStory(byId id: String?) {
    guard let storyId = id else {
      return
    }
    stateController.unArchiveStory(id: storyId)
  }
  
  func contributorsTextAt(index i: Int) -> String {
    // better username caching
    let contributorUsernames = self.managedStoryList.managedStories[i].contributorUsernames()
    let otherNames = contributorUsernames.filter { $0 != stateController.activeUsername}
    if otherNames.count > 0 {
      return otherNames.joined(separator: ", ")
    } else {
      return "(Just You)"
    }
  }
 
  func lastPositionAt(storyIndex i: Int) -> Int {
    let storyId = managedStoryIdAt(index: i)
    guard let lastPosition = storyScrollMap[storyId] else {
      let endPosition = numPagesInManagedStoryAt(index: i)
      storyScrollMap[storyId] = endPosition
      return endPosition
    }
    return lastPosition
  }
  
  func setStoryViewerStartingPoint(storyId: String, pageIndex: Int) {
    let story = stateController.activeUserStoryById(id: storyId)
    stateController.currentStory = story
    stateController.storyViewerIndex = pageIndex
  }
}
