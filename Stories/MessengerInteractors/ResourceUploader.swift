//
//  ResourceUploader.swift
//  Stories
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
    do {
      let resourceUrl = try apiWorker.urlOfEndpoint("/resources")
      let resource = Resource(data: data)
      let uploadData = try JSONEncoder().encode(resource)
      if (currentUser.getJWT() == nil) {
        let authenticator = Authenticator(localUser: currentUser)
        do {
          try authenticator.authenticate(completion: {(success) in
            if (!success || currentUser.getJWT() == nil) {
              print("Couldn't authenticate user for resource upload")
              completion(false, nil)
            }
          })
        } catch {
          completion(false, error.localizedDescription)
        }
      }
      apiWorker.post(url: resourceUrl, uploadData: uploadData, jwt: currentUser.getJWT(), completion: { (status, res) in
        guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
          print("failed to convert results to data")
          completion(false, nil)
          return
        }
        guard let resourceRes = try? JSONDecoder().decode(ResourceResult.self, from: resData) else {
          print("failed to decode resource post result into struct")
          completion(false, nil)
          return
        }
        if status == .ResourceCreated {
          completion(true, resourceRes.resourceId)
        } else {
          print("Resource creation failed with status: ", status)
          completion(false, nil)
        }
      })

    } catch {
      print("Error in uploadResource: ", error)
      completion(false, error.localizedDescription)
    }
  }
}
