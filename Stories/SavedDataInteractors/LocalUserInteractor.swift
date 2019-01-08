//
//  LocalUserInteractor.swift
//  Stories
//
//  Created by Chris on 1/3/19.
//  Copyright © 2019 Sun Canyon. All rights reserved.
//

import CoreData
import Foundation

class LocalUserInteractor {
  
  var managedContext: NSManagedObjectContext
  
  init(managedContext: NSManagedObjectContext) {
    self.managedContext = managedContext
  }
  
  func fetchLocalUsers() -> Array<LocalUserMO>? {
    let localUserFetchRequest = NSFetchRequest<LocalUserMO>(entityName: "LocalUser")
    localUserFetchRequest.predicate = NSPredicate(format: "(shouldBeDeleted == FALSE)")
    do {
      return try managedContext.fetch(localUserFetchRequest)
    } catch let error as NSError {
      print("Could not fetch users. \(error)")
      return nil
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
  
  func deleteLocalUsers(existingUsers: Array<LocalUserMO>) throws {
    for existingUser in existingUsers {
      managedContext.delete(existingUser)
    }
    try managedContext.save()
  }
  
  func deleteLocalUsersByName(_ name: String) throws {
    guard let users = fetchLocalUsersByName(name: name) else {
      print("No local users found by that name")
      return
    }
    try deleteLocalUsers(existingUsers: users)
  }
  
  func createLocalUser(name: String) throws -> LocalUserMO {
    let userEntity = NSEntityDescription.entity(forEntityName: "LocalUser", in: managedContext)!
    let newUser = LocalUserMO(entity: userEntity, insertInto: managedContext)
    newUser.setValue(name, forKey: "username")
    newUser.assignRandomPassword()
    try managedContext.save()
    return newUser
  }
  
  func setLocalUserToBeDeleted(_ user: LocalUserMO) throws {
    user.setValue(true, forKey: "shouldBeDeleted")
    try managedContext.save()
  }
  
  func markAsRegistered(_ user: LocalUserMO) throws {
    user.setValue(true, forKey: "isRegistered")
    try managedContext.save()
  }
  
}
