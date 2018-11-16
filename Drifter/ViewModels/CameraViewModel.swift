//
//  CameraViewModel.swift
//  Drifter
//
//  Created by Chris on 9/13/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation
import UIKit

class CameraViewModel {
  private var stateController: StateController!
  var userSearcher: UserSearcher
  
  var contributorResults: Array<String>
  var capturedImageData: Data?
  
  var capturedImage: UIImage? {
    guard let data = capturedImageData else {
      return nil
    }
    return UIImage(data: data)
  }
  
  var contributors: Array<String> {
    didSet {
      onContributorChange?()
    }
  }
  
  var onContributorChange: (() -> ())?
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
    self.userSearcher = UserSearcher()
    self.contributorResults = []
    self.contributors = []
    self.capturedImageData = nil
  }
  
  func setOnContributorChange(_ onContributorChangeFn: (() -> ())?) {
    self.onContributorChange = onContributorChangeFn
  }
  
  func createSinglePageStory(backgroundImagePNG: Data) -> StoryMO? {
    do {
      let page = try stateController.createNewPage(backgroundPNG: backgroundImagePNG, timestamp: Date())
      return stateController.createNewStory(withPages: [page])
    } catch {
      print(error)
      return nil
    }
  }
  
  func isReplying() -> Bool {
    return (stateController.replyingToStoryId != nil)
  }
  
  func addReply(backgroundImagePNG: Data?) throws {
    guard let imageData = backgroundImagePNG else {
      throw CameraViewError.NoImageProvided
    }
    let newPage = try stateController.createNewPage(backgroundPNG: imageData, timestamp: Date())
    try stateController.addReply(managedPage: newPage)
  }
  
  func handleCapture(backgroundImagePNG: Data) {
    self.capturedImageData = backgroundImagePNG
  }
  
  func handleSend(completion: @escaping (Bool) -> ()) throws {
    print("handle send being called")
    guard let imageData = capturedImageData else {
      throw CameraViewError.NoImageProvided
    }
    if isReplying() {
      print("I think we're replying to a story...")
      do {
        try addReply(backgroundImagePNG: imageData)
      } catch {
        print(error)
      }
    } else {
      guard let activeUser = self.stateController.activeUser else {
        throw CameraViewError.NoActiveUser
      }
      let storyStarter = StorySynchronizer(localUser: activeUser, stateController: stateController)
      print("abuot to create a new story...")
      guard let newStory = createSinglePageStory(backgroundImagePNG: imageData) else {
        throw CameraViewError.NoStoryProvided
      }
      for contributorName in contributors {
        guard let contributor = stateController.fetchUserByName(username: contributorName) else {
          print("failed to fetch contributor")
          continue
        }
        print("about to add to new story contributors...")
        newStory.addToContributors(contributor)
      }
      storyStarter.startStory(story: newStory, completion: {(success) in
        if (success) {
          self.stateController.addStoryToInbox(newStory)
          self.stateController.persistData()
        } else {
          print("story start failure")
        }
        completion(success)
      })
    }
  }
  
  func searchUsersFor(_ username: String, completion: @escaping (Bool) -> ()) {
    print("in searchUsersFor")
    do {
      try userSearcher.findMatchingUsers(username, completion: { results in
        print("in userSearcher.findMatchingUsers completion with results: ", results)
        self.contributorResults = results
        completion(true)
      })
    } catch {
      print(error)
      completion(false)
    }
  }
  
  func numSearchResults() -> Int {
    return contributorResults.count
  }
  
  func contributorResultAt(_ index: Int) -> String {
    return contributorResults[index]
  }
  
  func toggleContributor(_ username: String?) {
    guard let username = username else {
      return
    }
    if (!contributors.contains(username)) {
      contributors.append(username)
    } else {
      contributors = contributors.filter { $0 != username }
    }
  }
  
  func numContributors() -> Int {
    return contributors.count
  }
  
  func contributorAt(_ index: Int) -> String {
    return contributors[index]
  }
  
  func removeContributor(_ username: String?) {
    guard let username = username else {
      return
    }
    contributors = contributors.filter { $0 != username }
  }
  
  func isContributor(_ username: String?) -> Bool {
    guard let username = username else {
      return false
    }
    if contributors.contains(username) {
      return true
    } else {
      return false
    }
  }
  
}

enum CameraViewError: Swift.Error {
  case NoActiveUser
  case NoImageProvided
  case NoStoryProvided
}
