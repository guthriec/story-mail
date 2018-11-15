//
//  StoryStarter.swift
//  Drifter
//
//  Created by Chris on 11/14/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

struct Page: Codable {
  let timestamp: Date
  let backgroundResourceId: String
  let creator: String
}

struct StoryUpdate: Codable {
  let newPages: Array<Page>
  let storyId: String
}

class StoryStarter {
  let messageSender = MessageSender()
  let resourceUploader = ResourceUploader()
  
  var localUser: LocalUserMO
  
  init(localUser: LocalUserMO) {
    self.localUser = localUser
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
