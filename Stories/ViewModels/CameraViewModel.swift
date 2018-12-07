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
      self.contributors = replyStory.contributorUsernames().filter { $0 != self.stateController.activeUsername }
    } else {
      self.contributors = []
    }
  }
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
    self.userSearcher = UserSearcher()
    self.contributorResults = []
    self.contributors = []
    self.capturedImageData = nil
    updateContributorsForReplyStory()
    self.stateController.onReplyStateChange = updateContributorsForReplyStory
  }
  
  func setOnContributorChange(_ onContributorChangeFn: (() -> ())?) {
    self.onContributorChange = onContributorChangeFn
  }
  
  func createSinglePageStory(backgroundImagePNG: Data) -> StoryMO? {
    do {
      let page = try stateController.createNewPage(backgroundPNG: backgroundImagePNG, timestamp: Date())
      return try stateController.createNewStory(withPages: [page])
    } catch {
      print(error)
      return nil
    }
  }
  
  func isReplying() -> Bool {
    return (stateController.replyingToStoryId != nil)
  }
  
  func addReply(backgroundImagePNG: Data?) throws -> StoryMO? {
    guard let imageData = backgroundImagePNG else {
      throw CameraViewError.NoImageProvided
    }
    let newPage = try stateController.createNewPage(backgroundPNG: imageData, timestamp: Date())
    return try stateController.addReply(managedPage: newPage)
  }
  
  func handleCapture(backgroundImagePNG: Data) {
    self.capturedImageData = backgroundImagePNG
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
        storySynchronizer.updateStory(story: updatedStory, completion: {(success) in
          if (success) {
            self.stateController.persistData()
          } else {
            print("story update failure")
          }
          completion(success)
        })
      } catch {
        print(error)
      }
    } else {
      guard let newStory = createSinglePageStory(backgroundImagePNG: imageData) else {
        throw CameraViewError.NoStoryProvided
      }
      for contributorName in contributors {
        guard let contributor = stateController.fetchUserByName(username: contributorName) else {
          print("failed to fetch contributor")
          continue
        }
        //print("about to add to new story contributors...")
        newStory.addToContributors(contributor)
      }
      storySynchronizer.updateStory(story: newStory, completion: {(success) in
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
    //print("in searchUsersFor")
    let context = self.stateController.managedContext
    let userFetchRequest = NSFetchRequest<UserMO>(entityName: "User")
    if (username.count > 0) {
      userFetchRequest.predicate = NSPredicate(format: "username CONTAINS %@", username)
    }
    //TODO: Fetch limit
    //print("story fetch request: ", storyFetchRequest)
    var userResults = Array<UserMO>()
    do {
      userResults = try context.fetch(userFetchRequest)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
    print("Fetched users for username: ", userResults)
    let usernameResults = userResults.map { $0.username! }
    self.contributorResults = usernameResults.filter { $0 != self.stateController.activeUsername }
    do {
      try userSearcher.findMatchingUsers(username, completion: { results in
        //print("in userSearcher.findMatchingUsers completion with results: ", results)
        for remoteResult in results {
          if !self.contributorResults.contains(remoteResult) && remoteResult != self.stateController.activeUsername {
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
      guard let savedUsername = userSearcher.saveSearchResult(username: username, stateController: self.stateController)?.username! else {
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
