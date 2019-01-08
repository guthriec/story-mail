//
//  MessageSender.swift
//  Stories
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
  
  struct MessageSendResult: Decodable {
    let id: String
    
    enum CodingKeys: String, CodingKey {
      case id = "_id"
    }
  }
  
  let apiWorker: ApiWorker
  
  init() {
    self.apiWorker = ApiWorker()
  }

  func sendMessage(_ payload: String,
                   from currentUser: LocalUserMO,
                   to recipientName: String,
                   resourceIds: Array<String>,
                   completion: @escaping (Bool, String?) -> ()) {
    let message = Message(recipient: recipientName, payload: payload, resourceIds: resourceIds)
    do {
      let messageUrl = try apiWorker.urlOfEndpoint("/messages")
      let uploadData = try JSONEncoder().encode(message)
      apiWorker.post(url: messageUrl, uploadData: uploadData, jwt: currentUser.getJWT(), completion: { (status, res) in
        guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
          completion(false, nil)
          return
        }
        guard let postRes = try? JSONDecoder().decode(MessageSendResult.self, from: resData) else {
          print("couldn't convert json response to result struct")
          completion(false, nil)
          return
        }
        if status == .ResourceCreated {
          completion(true, postRes.id)
        } else {
          completion(false, nil)
        }
      })
    } catch {
      completion(false, error.localizedDescription)
    }

  }
}
