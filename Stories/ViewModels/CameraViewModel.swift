//
//  CameraViewModel.swift
//  Stories
//
//  Created by Chris on 9/13/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CameraViewModel {
  private var stateController: StateController!
  var userSearcher: UserSearcher
  
  var contributorResults: Array<String>
  var matchingContacts: Array<String>
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
  
  func updateContributorsForReplyStory() {
    if let replyStory = self.stateController.replyStory {
      self.contributors = replyStory.story.contributorUsernames().filter { $0 != self.stateController.activeUsername }
    } else {
      self.contributors = []
    }
  }
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
    self.userSearcher = UserSearcher()
    self.contributorResults = []
    self.matchingContacts = []
    self.contributors = []
    self.capturedImageData = nil
    updateContributorsForReplyStory()
    self.stateController.onReplyStateChange = updateContributorsForReplyStory
  }
  
  func setOnContributorChange(_ onContributorChangeFn: (() -> ())?) {
    self.onContributorChange = onContributorChangeFn
  }
  
  func createSinglePageStory(backgroundImagePNG: Data) -> ExtendedStory? {
    do {
      let page = try stateController.createNewPage(backgroundPNG: backgroundImagePNG, timestamp: Date())
      return try stateController.createNewExtendedStory(withPendingPages: [page])
    } catch {
      print(error)
      return nil
    }
  }
  
  func isReplying() -> Bool {
    return (stateController.replyStory != nil)
  }
  
  func addReply(backgroundImagePNG: Data?) throws -> ExtendedStory? {
    guard let imageData = backgroundImagePNG else {
      throw CameraViewError.NoImageProvided
    }
    let newPage = try stateController.createNewPage(backgroundPNG: imageData, timestamp: Date())
    return stateController.addReply(with: newPage)
  }
  
  func handleCapture(backgroundImagePNG: Data) {
    self.capturedImageData = backgroundImagePNG
  }
  
  func handleStoryUpdate(updatedStory: ExtendedStory, success: Bool, completion: @escaping (Bool) -> ()) {
    if (success) {
      do {
        try updatedStory.commitChanges()
        try self.stateController.managedContext.save()
        self.stateController.refreshStories()
        completion(true)
      } catch {
        print("error saving changes: ", error)
        completion(false)
      }
    } else {
      print("story update failure")
      completion(false)
    }
  }
  
  func handleSend(completion: @escaping (Bool) -> ()) throws {
    //print("handle send being called")
    guard let imageData = capturedImageData else {
      throw CameraViewError.NoImageProvided
    }
    guard let activeUser = self.stateController.activeUser else {
      throw CameraViewError.NoActiveUser
    }
    let storySynchronizer = StorySynchronizer(localUser: activeUser, stateController: stateController)

    if isReplying() {
      do {
        guard let updatedStory = try addReply(backgroundImagePNG: imageData) else {
          print("add reply failed")
          completion(false)
          return
        }
        stateController.replyStory = nil
        storySynchronizer.updateStory(extendedStory: updatedStory, completion: {(success) in
          self.handleStoryUpdate(updatedStory: updatedStory, success: success, completion: completion)
        })
      } catch {
        print("Error in handling reply send: ", error)
      }
    } else {
      // Creating a new story
      guard let newStory = createSinglePageStory(backgroundImagePNG: imageData) else {
        throw CameraViewError.NoStoryProvided
      }
      let userInteractor = UserInteractor(managedContext: stateController.managedContext)
      for contributorName in contributors {
        guard let contributor = userInteractor.fetchExact(username: contributorName) else {
          print("failed to fetch contributor")
          continue
        }
        //print("about to add to new story contributors...")
        newStory.story.addToContributors(contributor)
      }
      self.stateController.addExtendedStoryToInbox(newStory)
      storySynchronizer.updateStory(extendedStory: newStory, completion: {(success) in
        self.handleStoryUpdate(updatedStory: newStory, success: success, completion: completion)
      })
    }
  }
  
  func searchUsersFor(_ username: String, completion: @escaping (Bool) -> ()) {
    let userInteractor = UserInteractor(managedContext: stateController.managedContext)
    let usernameResults = userInteractor.fetchUsernamesMatchingPartial(username: username)
    self.matchingContacts = usernameResults.filter { $0 != self.stateController.activeUsername }
    do {
      try userSearcher.findMatchingUsers(username, completion: { results in
        //print("in userSearcher.findMatchingUsers completion with results: ", results)
        self.contributorResults = []
        for remoteResult in results {
          if !self.matchingContacts.contains(remoteResult) &&
             remoteResult != self.stateController.activeUsername {
            self.contributorResults.append(remoteResult)
          }
        }
        completion(true)
      })
    } catch {
      print("Error in CameraViewModel.searchUsersFor: ", error)
      completion(false)
    }
  }
  
  func numMatchingContacts() -> Int {
    return matchingContacts.count
  }
  
  func numSearchResults() -> Int {
    return contributorResults.count
  }
  
  func matchingContactResultAt(_ index: Int) -> String {
    return matchingContacts[index]
  }
  
  func contributorResultAt(_ index: Int) -> String {
    return contributorResults[index]
  }
  
  func toggleContributor(_ username: String?) throws {
    guard let username = username else {
      return
    }
    if (!contributors.contains(username)) {
      guard let savedUsername = try userSearcher.saveSearchResult(username: username, stateController: self.stateController)?.username! else {
        return
      }
      contributors.append(savedUsername)
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
