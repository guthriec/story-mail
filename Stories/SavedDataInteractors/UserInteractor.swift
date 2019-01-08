//
//  UserInteractor.swift
//  Stories
//
//  Created by Chris on 1/3/19.
//  Copyright © 2019 Sun Canyon. All rights reserved.
//

import CoreData
import Foundation

class UserInteractor {
  
  var managedContext: NSManagedObjectContext
  
  init(managedContext: NSManagedObjectContext) {
    self.managedContext = managedContext
  }
  
  func fetchUsernamesMatchingPartial(username: String) -> Array<String> {
    let userFetchRequest = NSFetchRequest<UserMO>(entityName: "User")
    if (username.count > 0) {
      userFetchRequest.predicate = NSPredicate(format: "username CONTAINS %@", username)
    }
    let sortDescriptor = NSSortDescriptor(key: "lastContacted", ascending: false)
    userFetchRequest.sortDescriptors = [sortDescriptor]
    //TODO: Fetch limit, sort by last contacted
    var userResults = Array<UserMO>()
    do {
      userResults = try managedContext.fetch(userFetchRequest)
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
    //print("Fetched users for username: ", userResults)
    return userResults.map { $0.username! }
  }
  
  func fetchExact(username: String) -> UserMO? {
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
  
  func fetchOrCreateUser(username: String, firstName: String, lastName: String) throws -> UserMO {
    if let existingUser = fetchExact(username: username) {
      //print("User already exists...")
      return existingUser
    }
    let userEntity = NSEntityDescription.entity(forEntityName: "User", in: managedContext)!
    let newUser = UserMO(entity: userEntity, insertInto: managedContext)
    
    newUser.setValue(username, forKey: "username")
    newUser.setValue(firstName, forKey: "firstName")
    newUser.setValue(lastName, forKey: "lastName")
    
    try managedContext.save()
    return newUser
  }
  
  func removeUser(_ user: UserMO) throws {
    managedContext.delete(user)
    try managedContext.save()
  }
  
  func didContact(username: String) throws {
    guard let existingUser = fetchExact(username: username) else {
      print("no such contact...")
      return
    }
    existingUser.setValue(Date(), forKey: "lastContacted")
    try managedContext.save()
  }
  
}
