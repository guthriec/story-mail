//
//  StateController.swift
//  Stories
//
//  Created by Chris on 9/13/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//  The StateController manages global application state.

import Foundation
import CoreData
import UIKit


// the ExtendedStory class represents a story with uncommitted (pending) changes
class ExtendedStory {
  var story: StoryMO
  var pendingPages: Array<PageMO>?
  
  init(story: StoryMO) {
    self.story = story
  }
  
  init(story: StoryMO, pendingPages: Array<PageMO>) {
    self.story = story
    self.pendingPages = pendingPages
  }
  
  func commitChanges() throws {
    guard let pendingPages = pendingPages else {
      return
    }
    try story.addPagesAndUpdate(pages: pendingPages)
    self.pendingPages = nil
  }
}

class StateController {
  
  // MARK: properties
  var managedContext: NSManagedObjectContext
  var inboxStories: StoryList
  var archivedStories: StoryList
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
  
  var replyStory: ExtendedStory? {
    didSet {
      onReplyStateChange?()
    }
  }
  var onReplyStateChange: (() -> ())?

  
  var currentStory: ExtendedStory?
  var storyViewerIndex: Int?
  
  init() {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    managedContext = appDelegate.persistentContainer.viewContext
    
    inboxStories = StoryList()
    archivedStories = StoryList()
    
    userDefaults = UserDefaults.standard
    populateLocalUsers()
    
    activeUsername = userDefaults.string(forKey: "defaultUsername")
    print(activeUsername ?? "no active username")
    guard let username = activeUsername else {
      activeUser = nil
      return
    }
    setActiveUser(name: username)
  }

  
  // MARK: user utilities
  
  func populateLocalUsers() {
    let localUserInteractor = LocalUserInteractor(managedContext: managedContext)
    localUsers = localUserInteractor.fetchLocalUsers()
  }
  
  func setActiveUser(name: String) {
    let localUserInteractor = LocalUserInteractor(managedContext: managedContext)
    guard let localUsers = localUsers else {
      return
    }
    var localUserMatches = localUsers.filter({ $0.username == name })
    if (localUsers.count == 0 || localUserMatches.count == 0) {
      do {
        try activeUser = localUserInteractor.createLocalUser(name: name)
        return
      } catch (StateError.UserAlreadyExists) {
        guard let retryMatches = localUserInteractor.fetchLocalUsersByName(name: name) else {
          return
        }
        localUserMatches = retryMatches
      } catch {
        return
      }
    }
    activeUser = localUserMatches[0]
    activeUsername = name
    //print("setting active user: ", activeUser?.value(forKey: "username") ?? "<no username for active user>")
    fetchSavedStoriesForActiveUser()
    self.inboxStories.sortStories()
    self.archivedStories.sortStories()
    synchronizeStoriesForActiveUser(completion: { success in
      print("Successfully synchronized stories for active user?: ", success)
    })
    userDefaults.set(name, forKey: "defaultUsername")
  }
  
  func deleteActiveUser() throws {
    guard let activeUser = activeUser else {
      print("No active user to delete...")
      return
    }
    let localUserInteractor = LocalUserInteractor(managedContext: managedContext)
    try localUserInteractor.setLocalUserToBeDeleted(activeUser)
    self.activeUser = nil
    activeUsername = nil
    userDefaults.setValue(nil, forKey: "defaultUsername")
    populateLocalUsers()
  }
  
  func fetchSavedStoriesForActiveUser() {
    guard let username = activeUsername, let _ = activeUser else {
      print("no active user")
      return
    }
    /*let allFetchRequest = NSFetchRequest<StoryMO>(entityName: "Story")
    do {
      let stories = try managedContext.fetch(allFetchRequest)
      for story in stories {
        _ = story.value(forKey: "owner")
      }
      // print("all fetch results: ", stories)
    } catch {
      print("failed to fetch all stories with error: ", error)
    }*/
    
    let storyInteractor = StoryInteractor(managedContext: managedContext)
    inboxStories.add(stories: storyInteractor.fetchInboxStories(username: username))
    archivedStories.add(stories: storyInteractor.fetchArchiveStories(username: username))
  }
  
  func synchronizeStoriesForLocalUser(_ user: LocalUserMO, completion: @escaping (Bool) -> ()) {
    let storySynchronizer = StorySynchronizer(localUser: user, stateController: self)
    //print("abbout to pullremotestories")
    storySynchronizer.pullRemoteStories(completion: {success in
      //print("In pullRemoteStories completion in SC.fetchStoriesForActiveUser")
      completion(success)
    })
  }
  
  func synchronizeStoriesForActiveUser(completion: @escaping(Bool) -> ()) {
    guard let activeUser = activeUser else {
      print("No active user for story sync...")
      completion(false)
      return
    }
    //print("aout to synchronize stories for local user")
    synchronizeStoriesForLocalUser(activeUser, completion: completion)
  }
  
  
  // MARK: story utilities
  
  func createNewPage(id: String, backgroundPNG: Data, timestamp: Date, authorName: String) -> PageMO? {
    let userInteractor = UserInteractor(managedContext: managedContext)
    var author = userInteractor.fetchExact(username: authorName)
    if author == nil {
      print("Could not get user with that authorName: ", authorName)
      do {
        try author = userInteractor.fetchOrCreateUser(username: authorName, firstName: "", lastName: "")
      } catch {
        print(error)
        return nil
      }
    }
    let pageEntity = NSEntityDescription.entity(forEntityName: "Page", in: managedContext)!
    let newManagedPage = PageMO(entity: pageEntity, insertInto: managedContext)
    do {
      try newManagedPage.setBackgroundImage(backgroundImagePNG: backgroundPNG)
    } catch {
      print(error)
      return nil
    }
    newManagedPage.setValue(id, forKey: "id")
    newManagedPage.setValue(timestamp, forKey: "timestamp")
    newManagedPage.setValue(author, forKey: "author")
    return newManagedPage
  }
  
  // Creates a new page with a generated UUID
  func createNewPage(backgroundPNG: Data, timestamp: Date, authorName: String) -> PageMO? {
    return createNewPage(id: UUID().uuidString, backgroundPNG: backgroundPNG, timestamp: timestamp,
                         authorName: authorName)
  }
  
  // Creates a new page with the current user
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
  
  func createNewExtendedStory(withPendingPages pages: Array<PageMO>) throws -> ExtendedStory {
    let newStory = try createStory(withId: UUID().uuidString)
    newStory.setValue(Date(), forKey: "lastUpdated")
    return ExtendedStory(story: newStory, pendingPages: pages)
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
    guard let existingStory = activeUserStoryById(id: id) else {
      return try createStory(withId: id)
    }
    return existingStory
  }
  
  func addStoryToInbox(_ newStory: StoryMO) {
    self.inboxStories.add(stories: [newStory])
    self.inboxStories.sortStories()
  }
  
  func addExtendedStoryToInbox(_ extendedStory: ExtendedStory) {
    self.inboxStories.add(extendedStory: extendedStory)
    self.inboxStories.sortStories()
    self.inboxStories.onStoryListChange()
  }
  
  func activeUserStoryById(id: String) -> StoryMO? {
    guard let activeUsername = activeUsername else {
      print("No active user")
      return nil
    }
    let storyInteractor = StoryInteractor(managedContext: managedContext)
    return storyInteractor.fetchStory(id: id, username: activeUsername)
  }
  
  func refreshStories() {
    inboxStories.sortStories()
    archivedStories.sortStories()
    inboxStories.onStoryListChange()
    archivedStories.onStoryListChange()
  }
  
  func addReply(with page: PageMO) -> ExtendedStory? {
    replyStory?.pendingPages = [page]
    self.refreshStories()
    return replyStory
  }
  
  func archiveStory(id: String) throws {
    guard let story = activeUserStoryById(id: id) else {
      print("archiveStory: no such story")
      return
    }
    let storyInteractor = StoryInteractor(managedContext: managedContext)
    try storyInteractor.archiveStory(story)
    self.inboxStories.removeStoryWith(id: id)
    self.archivedStories.add(stories: [story])
    archivedStories.sortStories()
  }
  
  func unArchiveStory(id: String) throws {
    guard let story = activeUserStoryById(id: id) else {
      print("unArchiveStory: no such story")
      return
    }
    let storyInteractor = StoryInteractor(managedContext: managedContext)
    try storyInteractor.unarchiveStory(story)
    self.archivedStories.removeStoryWith(id: id)
    self.inboxStories.add(stories: [story])
    inboxStories.sortStories()
  }
  
  func deleteStory(id: String) throws {
    guard let story = activeUserStoryById(id: id) else {
      print("no story found")
      return
    }
    let storyInteractor = StoryInteractor(managedContext: managedContext)
    try storyInteractor.deleteStory(story)
  }
  
  func addContributorsToStoryByUsername(story: StoryMO, usernames: Array<String>) throws {
    let userInteractor = UserInteractor(managedContext: managedContext)
    let storyInteractor = StoryInteractor(managedContext: managedContext)
    for username in usernames {
      guard let user = userInteractor.fetchExact(username: username) else {
        print("This user is unknown.....")
        return
      }
      try storyInteractor.addContributorToStory(story, contributor: user)
    }
  }
}

class StoryList {
  var extendedStories: Array<ExtendedStory> {
    didSet {
      onStoryListChange()
    }
  }
  
  private var onStoryListChangeFns: Array<(() -> ())?>

  init() {
    extendedStories = Array()
    onStoryListChangeFns = Array()
  }
  
  func clearStories() {
    extendedStories = Array()
  }
  
  func onStoryListChange() {
    for onStoryListChangeFn in self.onStoryListChangeFns {
      onStoryListChangeFn?()
    }
  }
  
  func add(extendedStory: ExtendedStory) {
    extendedStories.append(extendedStory)
  }
  
  func add(stories: Array<StoryMO?>?) {
    guard let stories = stories else {
      return
    }
    for story in stories {
      guard let newStory = story else {
        print("couldn't unwrap story...")
        continue
      }
      if !extendedStories.contains { extendedStory in
        if extendedStory.story == newStory {
          return true
        }
        return false
      } {
        let newExtendedStory = ExtendedStory(story: newStory)
        extendedStories.append(newExtendedStory)
      } else {
        print("found matching story")
      }
    }
  }
  
  func add(onStoryListChangeFn storyListChangeFn: (() -> ())?) {
    self.onStoryListChangeFns.append(storyListChangeFn)
  }
  
  func sortStories() {
    self.extendedStories.sort(by: { (story1, story2) -> Bool in
      guard let updated1 = story1.story.lastUpdated as Date? else {
        return false
      }
      guard let updated2 = story2.story.lastUpdated as Date? else {
        return true
      }
      return updated1 > updated2
    })
  }
  
  func removeStoryWith(id: String) {
    self.extendedStories = self.extendedStories.filter { $0.story.id != id }
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
