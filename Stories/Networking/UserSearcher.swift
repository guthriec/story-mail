//
//  UserSearcher.swift
//  Stories
//
//  Created by Chris on 11/13/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation
import CoreData

class UserSearcher {
  struct UserSearchResult: Decodable {
    let id: String
    let username: String
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
      case id = "_id"
      case username = "username"
      case firstName = "firstName"
      case lastName = "lastName"
    }
  }

  let apiWorker = ApiWorker()
  var currentSearchResults = [String : UserSearchResult]()
  
  func isUsernameAvailable() -> Bool {
    return false
  }
  
  func findMatchingUsers(_ query: String, completion: @escaping (Array<String>) -> ()) throws {
    guard let userUrl = apiWorker.urlWithQuery(endpointPath: "/users", queryName: "q", queryValue: query) else {
      throw UserSearcherError.BadQuery
    }
    apiWorker.get(url: userUrl, jwt: nil, completion: {(success, res) in
      guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
        print("Unparsable response")
        completion([])
        return
      }
      guard let searchRes = try? JSONDecoder().decode([UserSearchResult].self, from: resData) else {
        print("Unparsable response")
        completion([])
        return
      }
      for res in searchRes {
        self.currentSearchResults[res.username] = res
      }
      let names = searchRes.map { $0.username }
      completion(names)
    })
  }
  
  func saveSearchResult(username: String, stateController: StateController) -> UserMO? {
    guard let searchResult = currentSearchResults[username] else {
      print("No search result with that username")
      return nil
    }
    return stateController.createAndSaveRemoteUser(username: username,
                                                   firstName: searchResult.firstName,
                                                   lastName: searchResult.lastName)
  }  
}

enum UserSearcherError: Error {
  case BadQuery
  case UnparsableResponse
}
