//
//  UserMO+CoreDataProperties.swift
//  Drifter
//
//  Created by Chris on 11/7/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//

import Foundation
import CoreData


extension UserMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserMO> {
        return NSFetchRequest<UserMO>(entityName: "User")
    }

    @NSManaged public var username: String?
    @NSManaged public var pages: NSSet?
    @NSManaged public var stories: NSSet?

}

// MARK: Generated accessors for pages
extension UserMO {

    @objc(addPagesObject:)
    @NSManaged public func addToPages(_ value: PageMO)

    @objc(removePagesObject:)
    @NSManaged public func removeFromPages(_ value: PageMO)

    @objc(addPages:)
    @NSManaged public func addToPages(_ values: NSSet)

    @objc(removePages:)
    @NSManaged public func removeFromPages(_ values: NSSet)

}

// MARK: Generated accessors for stories
extension UserMO {

    @objc(addStoriesObject:)
    @NSManaged public func addToStories(_ value: StoryMO)

    @objc(removeStoriesObject:)
    @NSManaged public func removeFromStories(_ value: StoryMO)

    @objc(addStories:)
    @NSManaged public func addToStories(_ values: NSSet)

    @objc(removeStories:)
    @NSManaged public func removeFromStories(_ values: NSSet)

}
