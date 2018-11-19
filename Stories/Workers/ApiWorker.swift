//
//  ApiWorker.swift
//  Stories
//
//  Created by Chris on 11/7/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class ApiWorker {
  private var urlSession: URLSession
  
  private let apiBase: String
  
  init() {
    urlSession = URLSession(configuration: .default)
    let env = Bundle.main.infoDictionary!
    apiBase = env["API_BASE_URL"] as! String
  }
  
  func urlOfEndpoint(_ endpointPath: String) -> URL? {
    guard var urlComponents = URLComponents(string: apiBase) else {
      print("could not initiate url components from api base")
      return nil
    }
    urlComponents.path = endpointPath
    return urlComponents.url
  }
  
  func urlWithQuery(endpointPath: String, queryName: String, queryValue: String) -> URL? {
    // D.R.Y.
    guard var urlComponents = URLComponents(string: apiBase) else {
      print("could not initiate url components from api base")
      return nil
    }
    urlComponents.path = endpointPath
    urlComponents.queryItems = [URLQueryItem(name: queryName, value: queryValue)]
    return urlComponents.url
  }
  
  func post(url: URL, uploadData: Data, jwt: String?, completion: @escaping (Bool, String?) -> ()) {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let jwt = jwt {
      request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
    }
    let postTask = urlSession.uploadTask(with: request, from: uploadData) { data, res, err in
      if let error = err {
        completion(false, "network error: \(error)")
        return
      }
      guard let res = res as? HTTPURLResponse, [200, 201].contains(res.statusCode) else {
        guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
          completion(false, "server error")
          return
        }
        completion(false, dataString)
        return
      }
      if let data = data, let dataString = String(data: data, encoding: .utf8) {
        DispatchQueue.main.async {
          completion(true, dataString)
        }
      }
    }
    postTask.resume()
  }
  
  func get(url: URL, jwt: String?, completion: @escaping(Bool, String?) -> ()) {
    var request = URLRequest(url: url)
    if let jwt = jwt {
      request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
    }
    let getTask = urlSession.dataTask(with: request) { data, response, error in
      if let err = error {
        completion(false, "network error: \(err)")
        return
      }
      guard let res = response as? HTTPURLResponse, res.statusCode == 200 else {
        guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
          completion(false, "server error")
          return
        }
        completion(false, dataString)
        return
      }
      if let data = data, let dataString = String(data: data, encoding: .utf8) {
        DispatchQueue.main.async {
          completion(true, dataString)
        }
      }
    }
    getTask.resume()
  }
  
  func delete(url: URL, jwt: String?, completion: @escaping (Bool, String?) -> ()) {
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    if let jwt = jwt {
      request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
    }
    let deleteTask = urlSession.dataTask(with: request) { data, res, err in
      if let error = err {
        completion(false, "network error: \(error)")
        return
      }
      guard let res = res as? HTTPURLResponse, [200, 201].contains(res.statusCode) else {
        guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
          completion(false, "server error")
          return
        }
        completion(false, dataString)
        return
      }
      if let data = data, let dataString = String(data: data, encoding: .utf8) {
        DispatchQueue.main.async {
          completion(true, dataString)
        }
      }
    }
    deleteTask.resume()
  }
  
  /*func getData(url: URL, jwt: String?, completion: @escaping(Bool, Data?) -> ()) {
    var request = URLRequest(url: url)
    if let jwt = jwt {
      request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
      print("using JWT: ", jwt)
    }
    let getTask = urlSession.dataTask(with: request) { data, response, error in
      if let err = error {
        print("network error: ", err)
        completion(false, nil)
        return
      }
      guard let res = response as? HTTPURLResponse, res.statusCode == 200, let data = data else {
        print("server error")
        completion(false, nil)
        return
      }
      DispatchQueue.main.async {
        completion(true, data)
      }
    }
    getTask.resume()
  }*/
  
}

enum APIError: Error {
  case URLConstructionError
  case unknown
}
