//
//  ApiWorker.swift
//  Drifter
//
//  Created by Chris on 11/7/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class ApiWorker {
  var urlSession: URLSession
  var getTask: URLSessionDataTask?
  var postTask: URLSessionUploadTask?
  
  let apiBase: String
  
  init() {
    urlSession = URLSession(configuration: .default)
    apiBase = "http://10.0.0.217:3000"
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
    postTask?.cancel()
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let jwt = jwt {
      request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
    }
    postTask = urlSession.uploadTask(with: request, from: uploadData) { data, res, err in
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
    postTask?.resume()
  }
  
  func get(url: URL, completion: @escaping(Bool, String?) -> ()) {
    getTask?.cancel()
    getTask = urlSession.dataTask(with: url, completionHandler: {(data, response, error) in
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
    })
    getTask?.resume()
  }
  
}

enum APIError: Error {
  case URLConstructionError
  case unknown
}
