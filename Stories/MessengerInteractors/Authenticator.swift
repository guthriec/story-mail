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
  
  func authenticate(completion: @escaping (Bool) -> ()) throws {
    guard let username = self.username, let password = self.password else {
      throw AuthenticatorError.NoCredentialsProvided
    }
    let user = User(username: username, password: password)
    do {
      let authUrl = try apiWorker.urlOfEndpoint("/login")
      let uploadData = try JSONEncoder().encode(user)
      apiWorker.post(url: authUrl, uploadData: uploadData, jwt: nil, completion: { (status, res) in
        print("auth response: ", res ?? "nil")
        guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
          print("auth response could not be converted to data")
          completion(false)
          return
        }
        guard let authRes = try? JSONDecoder().decode(AuthResult.self, from: resData) else {
          print("auth response data not formated as expected: ", resData)
          completion(false)
          return
        }
        if status == .ResourceFound {
          self.localUser?.saveJWT(authRes.jwt)
          self.localUser?.lastAuthenticated = NSDate()
          completion(true)
        } else {
          completion(false)
        }
      })
    } catch {
      print(error)
      completion(false)
    }
  }
  
  func register(completion: @escaping (RegistrationStatus, String?) -> ()) throws {
    guard let username = self.username, let password = self.password else {
      throw AuthenticatorError.NoCredentialsProvided
    }
    let user = User(username: username, password: password)
    do {
      let registrationUrl = try apiWorker.urlOfEndpoint("/register")
      let uploadData = try JSONEncoder().encode(user)
      apiWorker.post(url: registrationUrl, uploadData: uploadData, jwt: nil, completion: { (status, res) in
        guard let resString = res, let resData = resString.data(using: String.Encoding.utf8) else {
          completion(.UnknownError, "response could not be converted to data")
          return
        }
        guard let authRes = try? JSONDecoder().decode(AuthResult.self, from: resData) else {
          completion(.UnknownError, "response data not formatted as expected")
          return
        }
        if status == .ServerError {
          completion(.NetworkError, nil)
        } else if status == .ResourceFound {
          completion(.AlreadyRegistered, nil)
        } else if status == .ResourceCreated {
          completion(.Registered, nil)
          self.localUser?.saveJWT(authRes.jwt)
        } else {
          completion(.UnknownError, nil)
        }
      })
    } catch {
      completion(.UnknownError, error.localizedDescription)
    }
  }
  
  func reauthenticateIfNecessary(completion: @escaping (Bool) -> ()) {
    var isAuthenticated = false
    if let lastAuthenticated = self.localUser?.lastAuthenticated {
      isAuthenticated = true
      if (abs(lastAuthenticated.timeIntervalSinceNow) > 60*60*23) {
        isAuthenticated = false
      }
    }
    if (!isAuthenticated) {
      do {
        try self.authenticate(completion: { success in
          completion(success)
        })
      } catch {
        print(error)
        completion(false)
      }
    } else {
      completion(true)
    }
  }

}


enum AuthenticatorError: Error {
  case BadEndpoint
  case NoCredentialsProvided
  case JSONEncodingError
}
