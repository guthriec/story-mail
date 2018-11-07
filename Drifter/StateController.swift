//
//  StateController.swift
//  Drifter
//
//  Created by Chris on 9/13/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class StateController {
  var managedContext: NSManagedObjectContext
  var managedInboxStories: ManagedStoryList
  var archivedStories: ManagedStoryList
  var activeUser: UserMO?
  
  var userDefaults: UserDefaults
  
  var activeUsername: String? {
    didSet {
      print("in didset")
      onActiveUserChange?()
    }
  }
  var localUserNames: Array<String>? {
    return userDefaults.stringArray(forKey: "localUserNames")
  }
  
  var replyingToStoryId: String?
  
  var onActiveUserChange: (() -> ())?
  
  func fetchUserByName(username: String) -> UserMO? {
    let userFetchRequest = NSFetchRequest<UserMO>(entityName: "User")
    userFetchRequest.predicate = NSPredicate(format: "username == %@", username)
    do {
      let userResults = try managedContext.fetch(userFetchRequest)
      if (userResults.count != 1) {
        print("no such user; or too many such users")
        return nil
      } else {
        return userResults[0]
      }
    } catch let error as NSError {
      print("Could not fetch user. \(error)")
      return nil
    }
  }
  
  func addLocalUsername(name: String) {
    print("should be adding a local username")
    if var localNames = localUserNames {
      localNames.append(name)
      userDefaults.set(localNames, forKey: "localUserNames")
    } else {
      userDefaults.set([name], forKey: "localUserNames")
    }
  }
  
  func createLocalUser(name: String) -> UserMO {
    print("should be creating a local user")
    let userEntity = NSEntityDescription.entity(forEntityName: "User", in: managedContext)!
    let newUser = UserMO(entity: userEntity, insertInto: managedContext)

    newUser.setValue(name, forKey: "username")
    self.persistData()
    addLocalUsername(name: name)
    return newUser
  }
  
  func setActiveUser(name: String) {
    let fetchedUser = fetchUserByName(username: name)
    if (fetchedUser == nil) {
      activeUser = createLocalUser(name: name)
    } else {
      activeUser = fetchedUser
    }
    activeUsername = name
    if let allLocalNames = localUserNames {
      if !allLocalNames.contains(name) {
        addLocalUsername(name: name)
      }
    } else {
      addLocalUsername(name: name)
    }
    guard let user = activeUser else {
      print("no active user shithead")
      return
    }
    print("setting active user: ", user.value(forKey: "username") ?? "<no username for active user>")
    fetchStoriesForActiveUser()
    userDefaults.set(name, forKey: "defaultUserName")
  }
  
  func fetchStoriesForActiveUser() {
    managedInboxStories.clearStories()
    archivedStories.clearStories()

    guard let username = activeUsername else {
      print("no active user")
      return
    }
    let inboxFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    inboxFetchRequest.predicate = NSPredicate(format: "(isArchived == FALSE) AND (ANY contributors.username == %@)", username)
    do {
      let initialInboxStories = try managedContext.fetch(inboxFetchRequest)
      managedInboxStories.add(stories: initialInboxStories)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
    
    let archiveFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    archiveFetchRequest.predicate = NSPredicate(format: "(isArchived == TRUE) AND (ANY contributors.username == %@)", username)
    do {
      let initialArchivedStories = try managedContext.fetch(archiveFetchRequest)
      archivedStories.add(stories: initialArchivedStories)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
    
    managedInboxStories.sortStories()
    archivedStories.sortStories()
  }
  
  init() {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    managedContext = appDelegate.persistentContainer.viewContext
    
    managedInboxStories = ManagedStoryList()
    archivedStories = ManagedStoryList()
    
    userDefaults = UserDefaults.standard
    activeUsername = userDefaults.string(forKey: "defaultUserName")
    print(activeUsername ?? "no active username")
    guard let username = activeUsername else {
      activeUser = nil
      return
    }
    activeUser = fetchUserByName(username: username)
    fetchStoriesForActiveUser()
  }
  
  func createNewPage(backgroundPNG: Data, timestamp: Date) throws -> PageMO {
    let pageEntity = NSEntityDescription.entity(forEntityName: "Page", in: managedContext)!
    let newManagedPage = PageMO(entity: pageEntity, insertInto: managedContext)
    do {
      try newManagedPage.setBackgroundImage(backgroundImagePNG: backgroundPNG)
    } catch {
      print(error)
      throw StateError.couldNotCreate
    }
    newManagedPage.setValue(timestamp, forKey: "timestamp")
    newManagedPage.setValue(self.activeUser!, forKey: "author")
    self.persistData()
    return newManagedPage
  }
  
  func createNewStory(withPages pages: Array<PageMO>) -> StoryMO {
    let storyEntity = NSEntityDescription.entity(forEntityName: "Story", in: managedContext)!
    let newManagedStory = StoryMO(entity: storyEntity, insertInto: managedContext)
    newManagedStory.setValue(UUID().uuidString, forKey: "id")
    newManagedStory.setValue(false, forKey: "isArchived")
    newManagedStory.setValue(Date.distantPast, forKey: "lastUpdated")
    for page in pages {
      do {
        try newManagedStory.addPageAndUpdate(page: page)
      } catch {
        print(error)
      }
    }
    //print("appending ", newManagedStory, " to managedInboxStories")
    //print("original count: ", self.managedInboxStories.managedStories.count)
    self.managedInboxStories.add(stories: [newManagedStory])
    self.managedInboxStories.sortStories()
    //print("later count: ", self.managedInboxStories.managedStories.count)
    self.persistData()
    return newManagedStory
  }
  
  func persistData() {
    do {
      try managedContext.save()
    } catch {
      print(error)
    }
  }
  
  func managedStoryById(id: String) -> StoryMO? {
    let storyFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    storyFetchRequest.predicate = NSPredicate(format: "id == %@", id)
    var storyResults = Array<StoryMO>()
    do {
      storyResults = try managedContext.fetch(storyFetchRequest)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
    guard (storyResults.count > 0) else {
      print("no such story")
      return nil
    }
    return storyResults[0]
  }
  
  func refreshStories() {
    managedInboxStories.onStoryListChange()
    archivedStories.onStoryListChange()
    managedInboxStories.sortStories()
    archivedStories.sortStories()
  }
  
  func addReply(managedPage: PageMO) throws {
    guard let replyId = replyingToStoryId else {
      throw StateError.noReplyStorySet
    }
    guard let replyStory = managedStoryById(id: replyId) else {
      print("story could not be found")
      return
    }
    try replyStory.addPageAndUpdate(page: managedPage)
    replyingToStoryId = nil
    self.refreshStories()
    self.persistData()
  }
  
  func archiveStory(id: String) {
    guard let story = managedStoryById(id: id) else {
      print("no such story")
      return
    }
    self.managedInboxStories.removeStoryWith(id: id)
    self.archivedStories.add(stories: [story])
    story.setValue(true, forKey: "IsArchived")
    archivedStories.sortStories()
    self.persistData()
  }
  
  func unArchiveStory(id: String) {
    guard let story = managedStoryById(id: id) else {
      print("no such story")
      return
    }
    self.archivedStories.removeStoryWith(id: id)
    self.managedInboxStories.add(stories: [story])
    story.setValue(false, forKey: "IsArchived")
    managedInboxStories.sortStories()
    self.persistData()
  }
  
  func deleteStory(id: String) {
    guard let story = managedStoryById(id: id) else {
      print("no story found")
      return
    }
    self.managedContext.delete(story)
    self.persistData()
  }
}


class ManagedStoryList {
  var managedStories: Array<StoryMO> {
    didSet {
      onStoryListChange()
    }
  }
  
  private var onStoryChangeFns: Array<(() -> ())?>

  init() {
    managedStories = Array()
    onStoryChangeFns = Array()
  }
  
  func clearStories() {
    managedStories = Array()
  }
  
  func onStoryListChange() {
    for onStoryChangeFn in self.onStoryChangeFns {
      onStoryChangeFn?()
    }
  }
  
  func add(stories: Array<StoryMO?>) {
    for story in stories {
      guard let newStory = story else {
        continue
      }
      managedStories.append(newStory)
    }
  }
  
  func add(onStoryChangeFn storyChangeFn: (() -> ())?) {
    self.onStoryChangeFns.append(storyChangeFn)
  }
  
  func sortStories() {
    self.managedStories.sort(by: { (story1, story2) -> Bool in
      guard let updated1 = story1.lastUpdated as Date? else {
        return false
      }
      guard let updated2 = story2.lastUpdated as Date? else {
        return true
      }
      return updated1 > updated2
    })
  }
  
  func removeStoryWith(id: String) {
    self.managedStories = self.managedStories.filter { $0.id != id }
  }
}

enum StateError: Swift.Error {
  case noReplyStorySet
  case noSuchStory
  case couldNotCreate
  case unknown
}
