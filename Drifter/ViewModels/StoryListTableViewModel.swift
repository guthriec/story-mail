//
//  StoryListTableViewModel.swift
//  Drifter
//
//  Created by Chris on 10/23/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation
import UIKit

struct PageData {
  var backgroundImagePNG: UIImage
  var timeString: String
}

class StoryListTableViewModel {
  var stateController: StateController
  var managedStoryList: ManagedStoryList
  
  init(stateController: StateController!, managedStoryList: ManagedStoryList) {
    self.stateController = stateController
    self.managedStoryList = managedStoryList
  }
  
  func setOnStoryChange(_ onStoryChange: (() -> ())?) {
    self.managedStoryList.add(onStoryChangeFn: onStoryChange)
  }
  
  func getPageData(fromManaged page: PageMO) -> PageData? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "h:mm a"
    let timeString = dateFormatter.string(from: page.timestamp! as Date)
    guard let backgroundImage = page.getBackgroundImage() else {
      print("getBackgroundImage failed")
      return nil
    }
    return PageData(backgroundImagePNG: backgroundImage,
                    timeString: timeString)
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
    print("getting nth page in managed story at ", i)
    guard let pageSet = self.managedStoryList.managedStories[i].pages else {
      print("couldn't get pageset")
      return nil
    }
    return getPageData(fromManaged: pageSet[n] as! PageMO)
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
}
