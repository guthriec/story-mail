//
//  StoryMO+CoreDataClass.swift
//  Drifter
//
//  Created by Chris on 10/24/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//

import Foundation
import CoreData

@objc(StoryMO)
public class StoryMO: NSManagedObject {
  func addPageAndUpdate(page: PageMO) throws {
    guard let timestamp = page.timestamp as Date? else {
      throw StoryError.PageNotTimestamped
    }
    guard (timestamp > self.lastUpdated! as Date) else {
      throw StoryError.PageOutOfOrder
    }
    self.addToPages(page)
    self.setValue(timestamp, forKey: "lastUpdated")
    let author = page.value(forKey: "author") as! UserMO
    if (!self.contributors!.contains(author)) {
      self.addToContributors(author)
    }
  }
  func contributorUsernames() -> Array<String> {
    var res = Array<String>()
    for contributor in self.contributors! {
      res.append((contributor as! UserMO).value(forKey: "username") as! String)
    }
    return res
  }
}

enum StoryError: Swift.Error {
  case PageOutOfOrder
  case PageNotTimestamped
}
