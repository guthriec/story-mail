//
//  ResourceUploader.swift
//  Drifter
//
//  Created by Chris on 11/14/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

struct Resource: Codable {
  let data: Data
}

class ResourceUploader {
  struct ResourceResult: Decodable {
    let success: Bool
    let resourceId: String
  }
  
  let apiWorker: ApiWorker
  
  init() {
    self.apiWorker = ApiWorker()
  }
  
  func uploadResource(_ data: Data,
                      from currentUser: LocalUserMO,
                      completion: @escaping (Bool, String?) -> ()) {
    guard let resourceUrl = apiWorker.urlOfEndpoint("/resources") else {
      print("Couldn't get resource api url")
      completion(false, nil)
      return
    }
    let resource = Resource(data: data)
    guard let uploadData = try? JSONEncoder().encode(resource) else {
      print("Couldn't encode resource")
      completion(false, nil)
      return
    }
    if (currentUser.getJWT() == nil) {
      let authenticator = Authenticator(localUser: currentUser)
      authenticator.authenticate(completion: {(success) in
        if (!success || currentUser.getJWT() == nil) {
          print("Couldn't authenticate user for resource upload")
          completion(false, nil)
        }
      })
    }
    apiWorker.post(url: resourceUrl, uploadData: uploadData, jwt: currentUser.getJWT(), completion: { (success, res) in
      if (!success) {
        completion(false, nil)
        return
      }
      guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
        completion(false, nil)
        return
      }
      guard let resourceRes = try? JSONDecoder().decode(ResourceResult.self, from: resData) else {
        completion(false, nil)
        return
      }
      completion(true, resourceRes.resourceId)
    })
  }
}
