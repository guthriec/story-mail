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
  var storyList: StoryList
  
  var storyScrollMap = [String : Int]()
  
  init(stateController: StateController!, storyList: StoryList) {
    self.stateController = stateController
    self.storyList = storyList
  }
  
  func setOnStoryListChange(_ onStoryChange: (() -> ())?) {
    self.storyList.add(onStoryListChangeFn: onStoryChange)
  }
  
  func numStories() -> Int {
    return self.storyList.extendedStories.count
  }
  
  func numPagesInExtendedStoryAt(index i: Int) -> Int {
    if (self.storyList.extendedStories.indices.contains(i)) {
      let extendedStory = self.storyList.extendedStories[i]
      var pendingPagesCount = 0
      if let pendingPages = extendedStory.pendingPages {
        pendingPagesCount = pendingPages.count
      }
      guard let pageSet = extendedStory.story.pages else {
        return pendingPagesCount
      }
      return pageSet.count + pendingPagesCount
    } else {
      return 0
    }
  }
  
  func extendedStoryIdAt(index i: Int) -> String {
    return self.storyList.extendedStories[i].story.id!
  }
  
  func nthPageInExtendedStoryAt(storyIndex i: Int, pageIndex n: Int) -> PageData? {
    let currentStory = self.storyList.extendedStories[i]
    guard let pageSet = currentStory.story.pages else {
      print("couldn't get pageset")
      return nil
    }
    // TODO: this should be factored out somewhere
    if n < pageSet.count {
      return PageData(fromManaged: pageSet[n] as! PageMO, activeUsername: stateController.activeUsername, status: nil)
    } else {
      guard let pendingPages = currentStory.pendingPages else {
        print("pageIndex out of range")
        return nil
      }
      if n - pageSet.count < pendingPages.count {
        return PageData(fromManaged: pendingPages[n - pageSet.count], activeUsername: stateController.activeUsername, status: .Sending)
      } else {
        print("pageIndex out of range")
        return nil
      }
    }
  }
  
  func deleteStory(byId id: String?) throws {
    guard let storyId = id else {
      return
    }
    storyList.removeStoryWith(id: storyId)
    try stateController.deleteStory(id: storyId)
  }
  
  func archiveStory(byId id: String?) throws {
    guard let storyId = id else {
      return
    }
    try stateController.archiveStory(id: storyId)
  }
  
  func unArchiveStory(byId id: String?) throws {
    guard let storyId = id else {
      return
    }
    try stateController.unArchiveStory(id: storyId)
  }
  
  func contributorsTextAt(index i: Int) -> String {
    // better username caching
    let contributorUsernames = self.storyList.extendedStories[i].story.contributorUsernames()
    let otherNames = contributorUsernames.filter { $0 != stateController.activeUsername}
    if otherNames.count > 0 {
      return otherNames.joined(separator: ", ")
    } else {
      return "(Just You)"
    }
  }
 
  func lastPositionAt(storyIndex i: Int) -> Int {
    let storyId = extendedStoryIdAt(index: i)
    guard let lastPosition = storyScrollMap[storyId] else {
      let endPosition = numPagesInExtendedStoryAt(index: i)
      storyScrollMap[storyId] = endPosition
      return endPosition
    }
    return lastPosition
  }
  
  func storyIndexFromId(storyId: String?) -> Int? {
    return self.storyList.extendedStories.firstIndex(where: { $0.story.id == storyId })
  }
  
  func setReplyStoryFromId(storyId: String) {
    if let index = storyIndexFromId(storyId: storyId) {
      stateController.replyStory = storyList.extendedStories[index]
    }
  }
  
  func setStoryViewerStartingPoint(storyIndex: Int, pageIndex: Int) {
    stateController.currentStory = storyList.extendedStories[storyIndex]
    stateController.storyViewerIndex = pageIndex
  }
}
