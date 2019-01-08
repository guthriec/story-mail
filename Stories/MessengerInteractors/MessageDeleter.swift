//
//  MessageDeleter.swift
//  Stories
//
//  Created by Chris on 11/19/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class MessageDeleter {
  
  struct MessageResult: Decodable {
    let success: Bool
  }
  
  let apiWorker: ApiWorker
  
  init() {
    self.apiWorker = ApiWorker()
  }
  
  func deleteMessage(_ id: String, from currentUser: LocalUserMO, completion: @escaping (Bool) -> ()) {
    do {
      let messageUrl = try apiWorker.urlOfEndpoint("/messages/" + id)
      apiWorker.delete(url: messageUrl, jwt: currentUser.getJWT(), completion: { (success, res) in
        if (!success) {
          print("message delete failed with response: ", res ?? "")
        }
        completion(success)
      })
    } catch {
      print(error)
      completion(false)
    }
  }
}
