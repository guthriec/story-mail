//
//  StoryMO+CoreDataClass.swift
//  Stories
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
    for existingPage in self.pages ?? [] {
      let existingPageMO = existingPage as! PageMO
      //print("existing id: ", existingPageMO.value(forKey: "id") ?? "no id provided")
      //print("new id: ", page.value(forKey: "id") ?? "no id provided")
      if existingPageMO.value(forKey: "id") as! String == page.value(forKey: "id") as! String {
        print("id match! ", existingPageMO.value(forKey: "id") ?? "nil...")
        throw StoryError.PageAlreadyAdded
      }
    }
    //print("all ids clear...")
    self.addToPages(page)
    if (timestamp > self.lastUpdated! as Date) {
      self.setValue(timestamp, forKey: "lastUpdated")
    }
    let author = page.value(forKey: "author") as! UserMO
    if (!self.contributors!.contains(author)) {
      self.addToContributors(author)
    }
  }
  
  func addPagesAndUpdate(pages: Array<PageMO>) throws {
    let inOrderPages = try pages.sorted(by: {(page1, page2) in
      guard let time1 = page1.timestamp as Date?, let time2 = page2.timestamp as Date? else {
        throw StoryError.PageNotTimestamped
      }
      return time1.compare(time2) == .orderedAscending
    })
    for page in inOrderPages {
      try self.addPageAndUpdate(page: page)
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
  case PageAlreadyAdded
}
