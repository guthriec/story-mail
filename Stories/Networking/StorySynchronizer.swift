//
//  StorySynchronizer.swift
//  Stories
//
//  Created by Chris on 11/14/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class StorySynchronizer {
  struct Page: Codable {
    let id: String
    let timestamp: Date
    let backgroundResourceId: String
    let creator: String
  }
  
  
  struct StoryUpdate: Codable {
    let newPages: Array<Page>
    let storyId: String
    let contributors: Array<String>
  }
  
  struct NewMessage: Codable {
    let id: String
    let payload: String
    let resourceIds: Array<String>
    
    enum CodingKeys: String, CodingKey {
      case id = "_id"
      case payload = "payload"
      case resourceIds = "resources"
    }
  }
  
  struct MessageResource: Codable {
    let resourceId: String
    let data: Data
  }

  
  let messageSender = MessageSender()
  let resourceUploader = ResourceUploader()
  let messageDeleter = MessageDeleter()
  var authenticator: Authenticator
  let apiWorker = ApiWorker()
  
  var localUser: LocalUserMO
  var stateController: StateController
  
  init(localUser: LocalUserMO, stateController: StateController) {
    self.localUser = localUser
    self.stateController = stateController
    self.authenticator = Authenticator(localUser: self.localUser)
  }
  
  private func newPagesForUpdate(_ update: StoryUpdate, resourceMap: [String : Data]) -> Array<PageMO> {
    var res = Array<PageMO>()
    print("extracting pages with resourceMap: ", resourceMap)
    for page in update.newPages {
      guard let backgroundData = resourceMap[page.backgroundResourceId] else {
        print("failed to extract image data from resource map", page.backgroundResourceId)
        continue
      }
      guard let newPage = stateController.createNewPage(backgroundPNG: backgroundData,
                                                        timestamp: page.timestamp,
                                                        authorName: page.creator)
        else {
          print("failed to create new page")
          continue
      }
      res.append(newPage)
    }
    print("NEWPAGES LENGTH: ", res.count)
    return res
  }
  
  private func getMessages(completion: @escaping (([String : StoryUpdate])?) -> ()) {
    guard let messageUrl = apiWorker.urlOfEndpoint("/messages") else {
      print("couldn't create message url endpoint in storysynchronizer.getupdates")
      completion(nil)
      return
    }
    apiWorker.get(url: messageUrl, jwt: self.localUser.getJWT(), completion: {(success, res) in
      guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
        print("Couldn't parse message response")
        completion(nil)
        return
      }
      guard let messageRes = try? JSONDecoder().decode([NewMessage].self, from: resData) else {
        print("Couldn't parse message JSON ^^ from: ", resString)
        completion(nil)
        return
      }
      
      var storyUpdates = [String : StoryUpdate]()
      
      for message in messageRes {
        
        // parse payload
        guard let payloadData = message.payload.data(using: String.Encoding.utf8) else {
          print("Couldn't parse message payload")
          completion(nil)
          return
        }
        guard let newStoryUpdate = try? JSONDecoder().decode(StoryUpdate.self, from: payloadData) else {
          print("Couldn't parse message payload JSON")
          completion(nil)
          return
        }
        storyUpdates[message.id] = newStoryUpdate
      }
      completion(storyUpdates)
    })
  }
  
  private func getResources(messageId: String, completion: @escaping ([String : Data]?) -> ()) {
    guard let resourcesUrl = apiWorker.urlOfEndpoint("/messages/" + messageId + "/resources") else {
      print("couldn't create resources url for message in getupdates")
      completion(nil)
      return
    }
    apiWorker.get(url: resourcesUrl, jwt: self.localUser.getJWT(), completion: {(success,res) in
      guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
        print("Couldn't parse resource message response")
        completion(nil)
        return
      }
      guard let resourceRes = try? JSONDecoder().decode([MessageResource].self, from: resData) else {
        print("Couldn't parse resource message JSON")
        completion(nil)
        return
      }
      var resourceMap = [String : Data]()
      for resource in resourceRes {
        resourceMap.updateValue(resource.data, forKey: resource.resourceId)
      }
      completion(resourceMap)
    })
  }
  
  private func deleteMessage(_ id: String, completion: @escaping (Bool) -> ()) {
    messageDeleter.deleteMessage(id, from: self.localUser, completion: { success in
      completion(success)
    });
  }
  
  private func reauthenticateIfNecessary(completion: @escaping (Bool) -> ()) {
    var isAuthenticated = false
    //print("accessing lastAuthenticated property: ", self.localUser.lastAuthenticated ?? "none")
    if let lastAuthenticated = self.localUser.lastAuthenticated {
      isAuthenticated = true
      if (lastAuthenticated.timeIntervalSinceNow > 60*60*23) {
        isAuthenticated = false
      }
    }
    if (!isAuthenticated) {
      authenticator.authenticate(completion: { success in
        //print("reauthenticated: ", success)
        completion(success)
      })
    } else {
      completion(true)
    }
  }
  
  func pullRemoteStories() {
    //print("pulling remote stories")
    reauthenticateIfNecessary(completion: {success in
      //print("reauthenticated?: ", success)
      self.getMessages(completion: {(updates) in
        guard let updates = updates else {
          print("getMessages passed in nil")
          return
        }
        var multiResourceMap = [String : Data]()
        var updatesForStories = [String : Array<StoryUpdate>]()
        var messageIds = Array<String>()
        var updateCounter = updates.count
        for (messageId, update) in updates {
          if updatesForStories[update.storyId]?.append(update) == nil {
            updatesForStories[update.storyId] = [update]
          }
          messageIds.append(messageId)
          self.getResources(messageId: messageId, completion: {(resourceMap) in
            guard let resourceMap = resourceMap else {
              print("getResources passed in nil")
              return
            }
            for (resourceId, data) in resourceMap {
              multiResourceMap[resourceId] = data
            }
            updateCounter -= 1
            print("Update counter: ", updateCounter)
            if updateCounter == 0 {
              print("Updates for stories: ", updatesForStories)
              for (storyId, updates) in updatesForStories {
                var pagesToAdd = Array<PageMO>()
                var contributorsToAdd = Array<String>()
                for update in updates {
                  pagesToAdd.append(contentsOf: self.newPagesForUpdate(update, resourceMap: multiResourceMap))
                  contributorsToAdd.append(contentsOf: update.contributors)
                }
                do {
                  let story = try self.stateController.findOrCreateStory(withId: storyId)
                  try story.addPagesAndUpdate(pages: pagesToAdd)
                  self.stateController.addContributorsToStoryByUsername(story: story, usernames: contributorsToAdd)
                  self.stateController.addStoryToInbox(story)
                } catch {
                  print("Error in adding pages to story: ", error)
                  return
                }
              }
              self.stateController.refreshStories()
              self.stateController.persistData()
              
              for messageId in messageIds {
                _ = self.deleteMessage(messageId, completion: { success in
                  print("Message deleted: ", success)
                })
              }
            }
          })
        }
      })
    })
  }
  
  func updateStory(story: StoryMO, completion: @escaping (Bool) -> ()) {
    let storyPages = story.pages?.array as! Array<PageMO>
    guard let mostRecentPage = storyPages.last else {
      print("No most recently added page")
      completion(false)
      return
    }
    guard let pageBackground = mostRecentPage.getBackgroundImageData() else {
      print("Could not get background image data of first page")
      completion(false)
      return
    }
    resourceUploader.uploadResource(pageBackground, from: localUser, completion: { (success, resourceId) in
      if (!success) {
        print("unknown resource upload error")
        completion(false)
        return
      } else {
        guard let resourceId = resourceId else {
          print("no resourceId provided after resource upload")
          completion(false)
          return
        }
        let creatorName = self.localUser.value(forKey: "username") as! String
        let page = Page(id: mostRecentPage.value(forKey: "id") as! String,
          timestamp: mostRecentPage.value(forKey: "timestamp") as! Date,
          backgroundResourceId: resourceId,
          creator: creatorName)
        var contributors = story.contributorUsernames()
        let storyUpdate = StoryUpdate(newPages: [page],
                                      storyId: story.value(forKey: "id") as! String,
                                      contributors: story.contributorUsernames())
        do {
          let payloadJson = try JSONEncoder().encode(storyUpdate)
          guard let payloadString = String(data: payloadJson, encoding: String.Encoding.utf8) else {
            print("could not formulate message payload string")
            completion(false)
            return
          }
          contributors = contributors.filter { $0 != creatorName }
          var numSuccessfulMessages = 0
          for contributor in contributors {
            print("sending message to recipient: ", contributor)
            self.messageSender.sendMessage(payloadString,
                                           from: self.localUser,
                                           to: contributor,
                                           resourceIds: [resourceId],
              completion: {(success, _) in
                if (!success) {
                  print("failed to send message")
                  completion(false)
                } else {
                  numSuccessfulMessages += 1
                  if (numSuccessfulMessages == contributors.count) {
                    print("calling completion on update story")
                    completion(true)
                  }
                }
              })
          }
        } catch {
          print("Error of questionable origin: ", error)
          completion(false)
        }
      }
    })
  }
}

enum StorySyncError {
  case NoLoggedInUser
}
