//
//  StoryInteractor.swift
//  Stories
//
//  Created by Chris on 1/3/19.
//  Copyright © 2019 Sun Canyon. All rights reserved.
//

import CoreData
import Foundation

class StoryInteractor {

  var managedContext: NSManagedObjectContext

  init(managedContext: NSManagedObjectContext) {
    self.managedContext = managedContext
  }
  
  func fetchInboxStories(username: String) -> Array<StoryMO>? {
    let inboxFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    print("fetching local stories for active user")
    inboxFetchRequest.predicate = NSPredicate(format: "(isArchived == FALSE) AND (owner.username == %@)", username)
    do {
      return try managedContext.fetch(inboxFetchRequest)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
      return nil
    }
  }
  
  func fetchArchiveStories(username: String) -> Array<StoryMO>? {
    let archiveFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    archiveFetchRequest.predicate = NSPredicate(format: "(isArchived == TRUE) AND (owner.username == %@)", username)
    do {
      return try managedContext.fetch(archiveFetchRequest)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
      return nil
    }
  }
  
  func fetchStory(id: String, username: String) -> StoryMO? {
    let storyFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    storyFetchRequest.predicate = NSPredicate(format: "(id == %@) AND (owner.username == %@)", id, username)
    //print("story fetch request: ", storyFetchRequest)
    var storyResults = Array<StoryMO>()
    do {
      storyResults = try managedContext.fetch(storyFetchRequest)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
    guard (storyResults.count > 0) else {
      print("activeUserStoryById: no such story")
      return nil
    }
    return storyResults[0]
  }
  
  func archiveStory(_ story: StoryMO) throws {
    story.setValue(true, forKey: "IsArchived")
    try managedContext.save()
  }
  
  func unarchiveStory(_ story: StoryMO) throws {
    story.setValue(false, forKey: "IsArchived")
    try managedContext.save()
  }
  
  func addContributorToStory(_ story: StoryMO, contributor: UserMO) throws {
    story.addToContributors(contributor)
    try managedContext.save()
  }
  
  func deleteStory(_ story: StoryMO) throws {
    self.managedContext.delete(story)
    try managedContext.save()
  }
}
