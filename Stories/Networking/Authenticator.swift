//
//  Authenticator.swift
//  Stories
//
//  Created by Chris on 11/10/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class Authenticator {
  struct User: Codable {
    let username: String
    let password: String
  }
  
  struct AuthResult: Decodable {
    let success: Bool
    let jwt: String
    
    enum CodingKeys: String, CodingKey {
      case success = "auth"
      case jwt = "token"
    }
  }
  
  var localUser: LocalUserMO?
  var username: String? {
    return localUser?.value(forKey: "username") as! String?
  }
  var password: String? {
    return localUser?.getPassword()
  }
  
  let apiWorker: ApiWorker
  
  
  init(localUser: LocalUserMO?) {
    self.localUser = localUser
    self.apiWorker = ApiWorker()
  }
  
  func isUsernameAvailable() -> Bool {
    return false
  }
  
  func authenticate(completion: @escaping (Bool) -> ()) {
    print("inside Authenticator.authenticate")
    guard let authUrl = apiWorker.urlOfEndpoint("/login") else {
      print("couldn't construct auth url")
      completion(false)
      return
    }
    guard let username = self.username, let password = self.password else {
      print("no username or password provided for auth")
      completion(false)
      return
    }
    let user = User(username: username, password: password)
    guard let uploadData = try? JSONEncoder().encode(user) else {
      print("could not encode user for auth")
      completion(false)
      return
    }
    apiWorker.post(url: authUrl, uploadData: uploadData,
                   jwt: nil,
    completion: { (success, res) in
      print(res ?? "no response")
      guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
        print("auth response could not be converted to data")
        completion(false)
        return
      }
      guard let authRes = try? JSONDecoder().decode(AuthResult.self, from: resData) else {
        print("auth response data not formated as expected")
        completion(false)
        return
      }
      self.localUser?.saveJWT(authRes.jwt)
      self.localUser?.lastAuthenticated = NSDate()
      completion(success)
    })
  }
  
  func register(completion: @escaping (Bool, String?) -> ()) {
    guard let registrationUrl = apiWorker.urlOfEndpoint("/register") else {
      completion(false, "Couldn't construct URL")
      return
    }
    guard let username = self.username, let password = self.password else {
      completion(false, "No username or password provided")
      return
    }
    let user = User(username: username, password: password)
    guard let uploadData = try? JSONEncoder().encode(user) else {
      completion(false, "Could not encode user")
      return
    }
    apiWorker.post(url: registrationUrl, uploadData: uploadData,
                   jwt: nil, completion: { (success, res) in
      print(res ?? "no response")
      guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
        completion(false, "response could not be converted to data")
        return
      }
      guard let authRes = try? JSONDecoder().decode(AuthResult.self, from: resData) else {
        completion(false, "response data not formatted as expected")
        return
      }
      self.localUser?.saveJWT(authRes.jwt)
      completion(success, res)
    })
  }
}

enum AuthenticatorError: Error {
  case BadEndpoint
}
