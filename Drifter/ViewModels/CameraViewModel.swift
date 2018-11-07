//
//  CameraViewModel.swift
//  Drifter
//
//  Created by Chris on 9/13/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation

class CameraViewModel {
  private var stateController: StateController!
  
  init(_ stateController: StateController!) {
    self.stateController = stateController
  }
  
  func createSinglePageStory(backgroundImagePNG: Data) {
    do {
      let page = try stateController.createNewPage(backgroundPNG: backgroundImagePNG, timestamp: Date())
      _ = stateController.createNewStory(withPages: [page])
      stateController.persistData()
    } catch {
      print(error)
    }
  }
  
  func isReplying() -> Bool {
    return (stateController.replyingToStoryId != nil)
  }
  
  func addReply(backgroundImagePNG: Data?) throws {
    guard let imageData = backgroundImagePNG else {
      throw CameraViewError.NoImageProvided
    }
    let newPage = try stateController.createNewPage(backgroundPNG: imageData, timestamp: Date())
    try stateController.addReply(managedPage: newPage)
  }
}

enum CameraViewError: Swift.Error {
  case NoImageProvided
}
