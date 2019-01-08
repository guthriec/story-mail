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

  func isUsernameAvailable(_ query: String, completion: @escaping (AvailabilityStatus) -> ()) {
    do {
      let userUrl = try apiWorker.urlWithQuery(endpointPath: "/exact-user", queryName: "q", queryValue: query)
      apiWorker.get(url: userUrl, jwt: nil, completion: {(status, res) in
        if status == .NoResourceFound {
          completion(.Available)
        } else if status == .ResourceFound {
          completion(.Unavailable)
        } else {
          print(res ?? "no error provided")
          completion(.NetworkError)
        }
      })
    } catch {
      completion(.UnknownError)
    }
  }
  
  func findMatchingUsers(_ query: String, completion: @escaping (Array<String>) -> ()) throws {
    do {
      let userUrl = try apiWorker.urlWithQuery(endpointPath: "/users", queryName: "q", queryValue: query)
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
    } catch {
      throw error
    }
  }
  
  // TODO: Move to SavedDataInteractor class
  func saveSearchResult(username: String, stateController: StateController) throws -> UserMO? {
    guard let searchResult = currentSearchResults[username] else {
      print("No search result with username: ", username)
      print("Current search results: ", self.currentSearchResults)
      return nil
    }
    let userInteractor = UserInteractor(managedContext: stateController.managedContext)
    return try userInteractor.fetchOrCreateUser(username: username,
                                                firstName: searchResult.firstName,
                                                lastName: searchResult.lastName)
  }  
}

enum UserSearcherError: Error {
  case BadQuery
  case UnparsableResponse
}
