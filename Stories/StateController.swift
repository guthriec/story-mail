//
//  StateController.swift
//  Stories
//
//  Created by Chris on 9/13/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class StateController {
  
  // MARK: properties
  var managedContext: NSManagedObjectContext
  var managedInboxStories: ManagedStoryList
  var archivedStories: ManagedStoryList
  var activeUser: LocalUserMO?
  var localUsers: Array<LocalUserMO>?
  
  var userDefaults: UserDefaults
  
  var activeUsername: String? {
    didSet {
      onActiveUserChange?()
    }
  }
  
  var onActiveUserChange: (() -> ())?
  
  var localUserNames: Array<String>? {
    return localUsers?.map { $0.username! }
  }
  
  var replyingToStoryId: String? {
    didSet {
      onReplyStateChange?()
    }
  }
  var onReplyStateChange: (() -> ())?
  
  var replyStory: StoryMO? {
    guard let storyId = replyingToStoryId else {
      return nil
    }
    return activeUserStoryById(id: storyId)
  }
  
  init() {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    managedContext = appDelegate.persistentContainer.viewContext
    
    managedInboxStories = ManagedStoryList()
    archivedStories = ManagedStoryList()
    
    userDefaults = UserDefaults.standard
    fetchLocalUsers()
    
    activeUsername = userDefaults.string(forKey: "defaultUsername")
    print(activeUsername ?? "no active username")
    guard let username = activeUsername else {
      activeUser = nil
      return
    }
    setActiveUser(name: username)
  }

  
  // MARK: user utilities
  func fetchUserByName(username: String) -> UserMO? {
    /*let allUserFetchRequest = NSFetchRequest<UserMO>(entityName: "User")
    do {
      print(try managedContext.fetch(allUserFetchRequest))
    } catch {
      print("alluserfetch error: ", error)
    }*/
    let userFetchRequest = NSFetchRequest<UserMO>(entityName: "User")
    userFetchRequest.predicate = NSPredicate(format: "username == %@", username)
    do {
      let userResults = try managedContext.fetch(userFetchRequest)
      if (userResults.count < 1) {
        print("no such user")
        return nil
      } else if (userResults.count > 1) {
        print("too many such users")
      }
      return userResults[0]
    } catch let error as NSError {
      print("Could not fetch user. \(error)")
      return nil
    }
  }
  
  func fetchLocalUsers() {
    let localUserFetchRequest = NSFetchRequest<LocalUserMO>(entityName: "LocalUser")
    localUserFetchRequest.predicate = NSPredicate(format: "(shouldBeDeleted == FALSE)")
    do {
      let localUserResults = try managedContext.fetch(localUserFetchRequest)
      localUsers = localUserResults
    } catch let error as NSError {
      print("Could not fetch users. \(error)")
      return
    }
  }
  
  func fetchLocalUsersByName(name: String) -> Array<LocalUserMO>? {
    let localUserFetchRequest = NSFetchRequest<LocalUserMO>(entityName: "LocalUser")
    localUserFetchRequest.predicate = NSPredicate(format: "(shouldBeDeleted == FALSE) AND (username == %@)", name)
    do {
      let localUserResults = try managedContext.fetch(localUserFetchRequest)
      return localUserResults
    } catch let error as NSError {
      print("Could not fetch users. \(error)")
      return nil
    }
  }
  
  func deleteLocalUser(name: String) {
    if let existingUsers = fetchLocalUsersByName(name: name) {
      print("deleting pre-existing users")
      for existingUser in existingUsers {
        managedContext.delete(existingUser)
      }
      self.persistData()
    }
  }
  
  func createLocalUser(name: String) throws -> LocalUserMO {
    let userEntity = NSEntityDescription.entity(forEntityName: "LocalUser", in: managedContext)!
    let newUser = LocalUserMO(entity: userEntity, insertInto: managedContext)

    newUser.setValue(name, forKey: "username")
    newUser.assignRandomPassword()
    return newUser
  }
  
  func createAndSaveRemoteUser(name: String) -> UserMO {
    if let existingUser = fetchUserByName(username: name) {
      print("User already exists...")
      return existingUser
    }
    let userEntity = NSEntityDescription.entity(forEntityName: "User", in: managedContext)!
    let newUser = UserMO(entity: userEntity, insertInto: managedContext)
    
    newUser.setValue(name, forKey: "username")
    self.persistData()
    return newUser
  }
  
  func saveLocalUser(_ : LocalUserMO) {
    self.persistData()
    fetchLocalUsers()
  }
  
  func setActiveUser(name: String) {
    guard let localUsers = localUsers else {
      return
    }
    var localUserMatches = localUsers.filter({ $0.username == name })
    if (localUsers.count == 0 || localUserMatches.count == 0) {
      do {
        try activeUser = createLocalUser(name: name)
        return
      } catch (StateError.UserAlreadyExists) {
        guard let retryMatches = fetchLocalUsersByName(name: name) else {
          return
        }
        localUserMatches = retryMatches
      } catch {
        return
      }
    }
    activeUser = localUserMatches[0]
    activeUsername = name
    print("setting active user: ", activeUser?.value(forKey: "username") ?? "<no username for active user>")
    fetchStoriesForActiveUser()
    userDefaults.set(name, forKey: "defaultUsername")
  }
  
  func deleteActiveUser() {
    activeUser?.setValue(true, forKey: "shouldBeDeleted")
    activeUser = nil
    activeUsername = nil
    userDefaults.setValue(nil, forKey: "defaultUsername")
    self.persistData()
    fetchLocalUsers()
  }
  
  func fetchStoriesForActiveUser() {
    managedInboxStories.clearStories()
    archivedStories.clearStories()

    guard let username = activeUsername, let activeUser = activeUser else {
      print("no active user")
      return
    }
    let allFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    do {
      let stories = try managedContext.fetch(allFetchRequest)
      for story in stories {
        _ = story.value(forKey: "owner")
      }
      // print("all fetch results: ", stories)
    } catch {
      print("failed to fetch all stories with error: ", error)
    }
    
    let inboxFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    print("fetching local stories for active user")
    inboxFetchRequest.predicate = NSPredicate(format: "(isArchived == FALSE) AND (owner.username == %@)", username)
    do {
      let initialInboxStories = try managedContext.fetch(inboxFetchRequest)
      managedInboxStories.add(stories: initialInboxStories)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
    
    let archiveFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    archiveFetchRequest.predicate = NSPredicate(format: "(isArchived == TRUE) AND (owner.username == %@)", username)
    do {
      let initialArchivedStories = try managedContext.fetch(archiveFetchRequest)
      archivedStories.add(stories: initialArchivedStories)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
    let storySynchronizer = StorySynchronizer(localUser: activeUser, stateController: self)
    storySynchronizer.pullRemoteStories()
    managedInboxStories.sortStories()
    archivedStories.sortStories()
  }
  
  // MARK: story utilities
  
  func createNewPage(backgroundPNG: Data, timestamp: Date, authorName: String) -> PageMO? {
    guard let author = fetchUserByName(username: authorName) else {
      print("Could not get user with that authorName: ", authorName)
      return nil
    }
    let pageEntity = NSEntityDescription.entity(forEntityName: "Page", in: managedContext)!
    let newManagedPage = PageMO(entity: pageEntity, insertInto: managedContext)
    do {
      try newManagedPage.setBackgroundImage(backgroundImagePNG: backgroundPNG)
    } catch {
      print(error)
      return nil
    }
    newManagedPage.setValue(UUID().uuidString, forKey: "id")
    newManagedPage.setValue(timestamp, forKey: "timestamp")
    newManagedPage.setValue(author, forKey: "author")
    return newManagedPage
  }
  
  func createNewPage(backgroundPNG: Data, timestamp: Date) throws -> PageMO {
    guard let currentUsername = activeUsername else {
      print("No logged in user")
      throw StateError.noLoggedInUser
    }
    guard let newPage = createNewPage(backgroundPNG: backgroundPNG,
                                      timestamp: timestamp, authorName: currentUsername) else {
      throw StateError.couldNotCreate
    }
    return newPage
  }
  
  func createNewStory(withPages pages: Array<PageMO>) throws -> StoryMO {
    let newStory = try createStory(withId: UUID().uuidString)
    for page in pages {
      do {
        try newStory.addPageAndUpdate(page: page)
      } catch {
        print(error)
      }
    }
    return newStory
  }
  
  func createStory(withId id: String) throws -> StoryMO {
    let storyEntity = NSEntityDescription.entity(forEntityName: "Story", in: managedContext)!
    let newManagedStory = StoryMO(entity: storyEntity, insertInto: managedContext)
    newManagedStory.setValue(id, forKey: "id")
    newManagedStory.setValue(false, forKey: "isArchived")
    newManagedStory.setValue(Date.distantPast, forKey: "lastUpdated")
    guard let activeUser = activeUser else {
      throw StateError.noLoggedInUser
    }
    newManagedStory.setValue(activeUser, forKey: "owner")
    return newManagedStory
  }
  
  func findOrCreateStory(withId id: String) throws -> StoryMO {
    print("IN FIND OR CREATE STORY")
    guard let existingStory = activeUserStoryById(id: id) else {
      return try createStory(withId: id)
    }
    print("STORY ALREADY EXISTS: ")
    return existingStory
  }
  
  func addStoryToInbox(_ newStory: StoryMO) {
    self.managedInboxStories.add(stories: [newStory])
    self.managedInboxStories.sortStories()
  }
  
  
  func activeUserStoryById(id: String) -> StoryMO? {
    guard let activeUsername = activeUsername else {
      print("No active user")
      return nil
    }
    let storyFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    storyFetchRequest.predicate = NSPredicate(format: "(id == %@) AND (owner.username == %@)", id, activeUsername)
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
  
  func refreshStories() {
    managedInboxStories.onStoryListChange()
    archivedStories.onStoryListChange()
    managedInboxStories.sortStories()
    archivedStories.sortStories()
  }
  
  func addReply(managedPage: PageMO) throws -> StoryMO? {
    guard let replyId = replyingToStoryId else {
      throw StateError.noReplyStorySet
    }
    guard let replyStory = activeUserStoryById(id: replyId) else {
      print("story could not be found")
      return nil
    }
    try replyStory.addPageAndUpdate(page: managedPage)
    replyingToStoryId = nil
    self.refreshStories()
    return replyStory
  }
  
  func archiveStory(id: String) {
    guard let story = activeUserStoryById(id: id) else {
      print("archiveStory: no such story")
      return
    }
    self.managedInboxStories.removeStoryWith(id: id)
    self.archivedStories.add(stories: [story])
    story.setValue(true, forKey: "IsArchived")
    archivedStories.sortStories()
    self.persistData()
  }
  
  func unArchiveStory(id: String) {
    guard let story = activeUserStoryById(id: id) else {
      print("unArchiveStory: no such story")
      return
    }
    self.archivedStories.removeStoryWith(id: id)
    self.managedInboxStories.add(stories: [story])
    story.setValue(false, forKey: "IsArchived")
    managedInboxStories.sortStories()
    self.persistData()
  }
  
  func deleteStory(id: String) {
    guard let story = activeUserStoryById(id: id) else {
      print("no story found")
      return
    }
    self.managedContext.delete(story)
    self.persistData()
  }
  
  func addContributorsToStoryByUsername(story: StoryMO, usernames: Array<String>) {
    for username in usernames {
      guard let user = fetchUserByName(username: username) else {
        story.addToContributors(createAndSaveRemoteUser(name: username))
        return
      }
      story.addToContributors(user)
    }
  }
  
  func persistData() {
    do {
      try managedContext.save()
    } catch {
      print(error)
    }
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
      if !managedStories.contains(newStory) {
        managedStories.append(newStory)
      }
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
  case noLoggedInUser
  case UserAlreadyExists
  case unknown
}
