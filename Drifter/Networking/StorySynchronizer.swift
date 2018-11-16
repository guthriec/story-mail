//
//  StorySynchronizer.swift
//  Drifter
//
//  Created by Chris on 11/14/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class StorySynchronizer {
  struct Page: Codable {
    let timestamp: Date
    let backgroundResourceId: String
    let creator: String
  }
  
  struct StoryUpdate: Codable {
    let newPages: Array<Page>
    let storyId: String
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
  let apiWorker = ApiWorker()
  
  var localUser: LocalUserMO
  var stateController: StateController
  
  init(localUser: LocalUserMO, stateController: StateController) {
    self.localUser = localUser
    self.stateController = stateController
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
      
      print("received messages: ", messageRes)
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
        print("New story update!: ", newStoryUpdate)
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
    print("getting resources for user: ", self.localUser.value(forKey: "username") ?? "no such user")
    print("with JWT: ", self.localUser.getJWT() ?? "no JWT")
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
        print("resource found with id: ", resource.resourceId)
        print("resource data: ", resource.data)
        resourceMap.updateValue(resource.data, forKey: resource.resourceId)
      }
      completion(resourceMap)
    })
  }
  
  // URGENT TODO: parallelize, this won't work except in cases of single-page updates
  func pullRemoteStories() {
    print("pulling remote stories")
    getMessages(completion: {(updates) in
      guard let updates = updates else {
        print("getMessages passed in nil")
        return
      }
      for (messageId, update) in updates {
        self.getResources(messageId: messageId, completion: {(resourceMap) in
          guard let resourceMap = resourceMap else {
            print("getResources passed in nil")
            return
          }
          let pagesToAdd = self.newPagesForUpdate(update, resourceMap: resourceMap)
          let story = self.stateController.findOrCreateStory(withId: update.storyId)
          for pageToAdd in pagesToAdd {
            do {
              try story.addPageAndUpdate(page: pageToAdd)
              print("successfully added page to story: ", story)
            } catch {
              print("Error in addpageandupdate: ", error)
              return
            }
          }
          self.stateController.addStoryToInbox(story)
          self.stateController.refreshStories()
          self.stateController.persistData()
        })
      }
    })
  }
  
  func startStory(story: StoryMO, completion: @escaping (Bool) -> ()) {
    let storyPages = story.pages?.array as! Array<PageMO>
    if (storyPages.count < 1) {
      print("Not enough pages to start story")
      completion(false)
      return
    }
    let firstPage = storyPages[0]
    guard let pageBackground = firstPage.getBackgroundImageData() else {
      print("Could not get background image data of first page")
      completion(false)
      return
    }
    let contributors = story.contributorUsernames()
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
        let page = Page(timestamp: firstPage.value(forKey: "timestamp") as! Date,
                        backgroundResourceId: resourceId,
                        creator: self.localUser.value(forKey: "username") as! String)
        let storyUpdate = StoryUpdate(newPages: [page],
                                      storyId: story.value(forKey: "id") as! String)
        do {
          let payloadJson = try JSONEncoder().encode(storyUpdate)
          guard let payloadString = String(data: payloadJson, encoding: String.Encoding.utf8) else {
            print("could not formulate message payload string")
            completion(false)
            return
          }
          for contributor in contributors {
            print("sending message to recipient: ", contributor)
            self.messageSender.sendMessage(payloadString,
                                           from: self.localUser,
                                           to: contributor,
                                           resourceIds: [resourceId],
              completion: {(success) in
                if (!success) {
                  print("failed to send message")
                }
                completion(success)
              })
          }
        } catch {
          print(error)
          completion(false)
          return
        }
      }
    })
  }
}
