//
//  PageMO+CoreDataClass.swift
//  Drifter
//
//  Created by Chris on 10/24/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit

@objc(PageMO)
public class PageMO: NSManagedObject {
  
  private func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
  }
  
  func setBackgroundImage(backgroundImagePNG data: Data?) throws {
    let id = UUID().uuidString
    let fileURL = getDocumentsDirectory().appendingPathComponent(id + ".png")
    do {
      print("trying to write data to: ", fileURL)
      try data?.write(to: fileURL)
    } catch {
      print(error)
      throw(PageError.FileError)
    }
    print(FileManager.default.fileExists(atPath: fileURL.path))
    assert(FileManager.default.fileExists(atPath: fileURL.path))
    self.setValue(id + ".png", forKey: "backgroundImageRelativePath")
  }
  
  func getBackgroundImage() -> UIImage? {
    guard let backgroundURLPath = self.value(forKey: "backgroundImageRelativePath") as! String? else {
      print("no URL string provided")
      return nil
    }
    let imagePath = getDocumentsDirectory().appendingPathComponent(backgroundURLPath).path
    guard let image = UIImage(contentsOfFile: imagePath) else {
      print("could not load image from file: ", imagePath)
      return nil
    }
    return image
  }
  
  func getBackgroundImageData() -> Data? {
    guard let backgroundURLPath = self.value(forKey: "backgroundImageRelativePath") as! String? else {
      print("no URL string provided")
      return nil
    }
    let imageUrl = getDocumentsDirectory().appendingPathComponent(backgroundURLPath)
    do {
      return try Data(contentsOf: imageUrl)
    } catch {
      print(error)
      return nil
    }
  }
  
  func deleteBackgroundImage() -> Bool {
    guard let backgroundURLPath = self.value(forKey: "backgroundImageRelativePath") as! String? else {
      print("no URL string provided")
      return false
    }
    let imageUrl = getDocumentsDirectory().appendingPathComponent(backgroundURLPath)
    do {
      try FileManager.default.removeItem(at: imageUrl)
      print("image deleted")
      return true
    } catch {
      print(error)
      return false
    }
  }
  
  override public func prepareForDeletion() {
    print("successfully deleted image: ", self.deleteBackgroundImage())
  }
  
}

enum PageError: Swift.Error {
  case FileError
}
