//
//  MessageSender.swift
//  Drifter
//
//  Created by Chris on 11/14/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class MessageSender {
  struct Message: Codable {
    let recipient: String
    let payload: String
    let resourceIds: Array<String>
  }
  
  struct MessageResult: Decodable {
    let success: Bool
  }
  
  let apiWorker: ApiWorker
  
  init() {
    self.apiWorker = ApiWorker()
  }

  func sendMessage(_ payload: String,
                   from currentUser: LocalUserMO,
                   to recipientName: String,
                   resourceIds: Array<String>,
                   completion: @escaping (Bool) -> ()) {
    guard let messageUrl = apiWorker.urlOfEndpoint("/messages") else {
      print("Couldn't get message api url")
      completion(false)
      return
    }
    let message = Message(recipient: recipientName, payload: payload, resourceIds: resourceIds)
    guard let uploadData = try? JSONEncoder().encode(message) else {
      print("Couldn't encode user")
      completion(false)
      return
    }
    apiWorker.post(url: messageUrl, uploadData: uploadData, jwt: currentUser.getJWT(), completion: { (success, res) in
      if (!success) {
        print("message post failed with response: ", res ?? "")
      }
      completion(success)
    })
  }
}
