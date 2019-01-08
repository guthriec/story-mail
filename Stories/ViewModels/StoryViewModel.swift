//
//  StoryViewModel.swift
//  Stories
//
//  Created by Chris on 11/29/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class StoryViewModel {
  var stateController: StateController
  
  var currentPageData: PageData?
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
    _ = setCurrentPage()
  }
  
  func setCurrentPage() -> Bool {
    guard let index = stateController.storyViewerIndex else {
      return false
    }
    guard let currentStory = stateController.currentStory else {
      return false
    }
    guard let pageCount = currentStory.story.pages?.count else {
      return false
    }
    if index < pageCount {
      guard let currentPage = currentStory.story.pages?[index] as! PageMO? else {
        return false
      }
      currentPageData = PageData(fromManaged: currentPage,
                                 activeUsername: stateController.activeUsername,
                                 status: nil)
    } else {
      if let pendingPages = currentStory.pendingPages {
        if index - pageCount < pendingPages.count {
          currentPageData = PageData(fromManaged: pendingPages[index - pageCount], activeUsername: stateController.activeUsername, status: .Sending)
        } else {
          return false
        }
      } else {
        return false
      }
    }
    return true
  }
  
  func advanceStory() -> Bool {
    guard let currIndex = stateController.storyViewerIndex else {
      return false
    }
    guard let currentStory = stateController.currentStory else {
      return false
    }
    guard let pages = currentStory.story.pages else {
      return false
    }
    if currIndex < pages.count - 1 {
      stateController.storyViewerIndex = currIndex + 1
      return setCurrentPage()
    } else {
      return false
    }
  }
  
  func rewindStory() -> Bool {
    guard let currIndex = stateController.storyViewerIndex else {
      return false
    }
    if currIndex > 0 {
      stateController.storyViewerIndex = currIndex - 1
      return setCurrentPage()
    } else {
      return false
    }
  }

}
