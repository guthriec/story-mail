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
  
  struct SimpleStoryUpdate: Codable {
    let newPages: Array<Page>
    let storyId: String
    let contributors: Array<String>
  }
  
  struct IndexedStoryUpdate: Codable {
    let newPages: Dictionary<Int, Page>
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
  
  private func newPagesForUpdate(_ update: SimpleStoryUpdate, resourceMap: [String : Data]) -> Array<PageMO>? {
    var res = Array<PageMO>()
    //print("extracting pages with resourceMap: ", resourceMap)
    for page in update.newPages {
      guard let backgroundData = resourceMap[page.backgroundResourceId] else {
        print("failed to extract image data from resource map", page.backgroundResourceId)
        return nil
      }
      guard let newPage = stateController.createNewPage(id: page.id, backgroundPNG: backgroundData,
                                                        timestamp: page.timestamp,
                                                        authorName: page.creator)
        else {
          print("failed to create new page")
          return nil
      }
      res.append(newPage)
    }
    return res
  }
  
  private func getMessages(completion: @escaping (([String : SimpleStoryUpdate])?) -> ()) {
    do {
      let messageUrl = try apiWorker.urlOfEndpoint("/messages")
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
        
        var storyUpdates = [String : SimpleStoryUpdate]()
        
        for message in messageRes {
          
          // parse payload
          guard let payloadData = message.payload.data(using: String.Encoding.utf8) else {
            print("Couldn't parse message payload")
            completion(nil)
            return
          }
          guard let newStoryUpdate = try? JSONDecoder().decode(SimpleStoryUpdate.self, from: payloadData) else {
            print("Couldn't parse message payload JSON")
            completion(nil)
            return
          }
          storyUpdates[message.id] = newStoryUpdate
        }
        completion(storyUpdates)
      })
    } catch {
      completion(nil)
    }
  }
  
  private func getResources(messageId: String, completion: @escaping ([String : Data]?) -> ()) {
    do {
      let resourcesUrl = try apiWorker.urlOfEndpoint("/messages/" + messageId + "/resources")
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
    } catch {
      completion(nil)
    }
  }
  
  private func deleteMessage(_ id: String, completion: @escaping (Bool) -> ()) {
    messageDeleter.deleteMessage(id, from: self.localUser, completion: { success in
      completion(success)
    })
  }
    
  func pullRemoteStories(completion: @escaping (Bool) -> ()) {
    //print("about to reauth if necessary")
    authenticator.reauthenticateIfNecessary(completion: {success in
      if(!success) {
        print("couldn't reauthenticate")
        completion(false)
        return
      }
      //print("about to getMessages")
      self.getMessages(completion: {(updates) in
        guard let updates = updates else {
          print("getMessages updates was nil")
          completion(false)
          return
        }
        var multiResourceMap = [String : Data]()
        var updatesForStories = [String : Array<SimpleStoryUpdate>]()
        var messageIds = Array<String>()
        var updateCounter = updates.count
        if updateCounter == 0 {
          //print("No new updates")
          completion(true)
        }
        for (messageId, update) in updates {
          if updatesForStories[update.storyId]?.append(update) == nil {
            updatesForStories[update.storyId] = [update]
          }
          messageIds.append(messageId)
          self.getResources(messageId: messageId, completion: {(resourceMap) in
            guard let resourceMap = resourceMap else {
              print("getResources passed in nil")
              completion(false)
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
                  guard let newPages = self.newPagesForUpdate(update, resourceMap: multiResourceMap) else {
                    print("Couldn't extract pages from update")
                    continue
                  }
                  pagesToAdd.append(contentsOf: newPages)
                  contributorsToAdd.append(contentsOf: update.contributors)
                }
                do {
                  let story = try self.stateController.findOrCreateStory(withId: storyId)
                  try story.addPagesAndUpdate(pages: pagesToAdd)
                  try self.stateController.addContributorsToStoryByUsername(story: story, usernames: contributorsToAdd)
                  self.stateController.addStoryToInbox(story)
                } catch {
                  print("Error in adding pages to story: ", error)
                  continue
                }
              }
              //self.stateController.persistData()
              //self.stateController.refreshStories()
              completion(true)
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
  
  func updateStory(extendedStory: ExtendedStory, completion: @escaping (Bool) -> ()) {
    authenticator.reauthenticateIfNecessary(completion: {success in
      if(!success) {
        print("couldn't reauthenticate")
        completion(false)
        return
      }
      guard let updatePages = extendedStory.pendingPages else {
        print("No pending pages")
        completion(false)
        return
      }
      guard let mostRecentPage = updatePages.last else {
        print("No most recently added page")
        completion(false)
        return
      }
      guard let pageBackground = mostRecentPage.getBackgroundImageData() else {
        print("Could not get background image data of first page")
        completion(false)
        return
      }
      self.resourceUploader.uploadResource(pageBackground, from: self.localUser, completion: { (success, resourceId) in
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
          var contributors = extendedStory.story.contributorUsernames()
          let storyUpdate = SimpleStoryUpdate(newPages: [page],
                                              storyId: extendedStory.story.value(forKey: "id") as! String,
                                              contributors: contributors)
          do {
            let payloadJson = try JSONEncoder().encode(storyUpdate)
            guard let payloadString = String(data: payloadJson, encoding: String.Encoding.utf8) else {
              print("could not formulate message payload string")
              completion(false)
              return
            }
            contributors = contributors.filter { $0 != creatorName }
            let userInteractor = UserInteractor(managedContext: self.stateController.managedContext)
            var numSuccessfulMessages = 0
            for contributor in contributors {
              print("sending message to recipient: ", contributor)
              self.messageSender.sendMessage(payloadString, from: self.localUser, to: contributor, resourceIds: [resourceId], completion: {(success, _) in
                if (!success) {
                  print("failed to send message")
                  completion(false)
                } else {
                  do {
                    try userInteractor.didContact(username: contributor)
                  } catch {
                    print("Error registering send with user lastContacted")
                  }
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

    })
  }
}

enum StorySyncError {
  case NoLoggedInUser
}
