//
//  LocalUserMO+CoreDataProperties.swift
//  Stories
//
//  Created by Chris on 11/19/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//

import Foundation
import CoreData


extension LocalUserMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalUserMO> {
        return NSFetchRequest<LocalUserMO>(entityName: "LocalUser")
    }

    @NSManaged public var shouldBeDeleted: Bool
    @NSManaged public var lastAuthenticated: NSDate?
    @NSManaged public var ownStories: NSSet?

}

// MARK: Generated accessors for ownStories
extension LocalUserMO {

    @objc(addOwnStoriesObject:)
    @NSManaged public func addToOwnStories(_ value: StoryMO)

    @objc(removeOwnStoriesObject:)
    @NSManaged public func removeFromOwnStories(_ value: StoryMO)

    @objc(addOwnStories:)
    @NSManaged public func addToOwnStories(_ values: NSSet)

    @objc(removeOwnStories:)
    @NSManaged public func removeFromOwnStories(_ values: NSSet)

}
