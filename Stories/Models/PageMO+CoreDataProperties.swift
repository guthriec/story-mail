//
//  PageMO+CoreDataProperties.swift
//  Stories
//
//  Created by Chris on 11/17/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//

import Foundation
import CoreData


extension PageMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PageMO> {
        return NSFetchRequest<PageMO>(entityName: "Page")
    }

    @NSManaged public var backgroundImageRelativePath: String?
    @NSManaged public var id: String?
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var author: UserMO?
    @NSManaged public var stories: NSSet?

}

// MARK: Generated accessors for stories
extension PageMO {

    @objc(addStoriesObject:)
    @NSManaged public func addToStories(_ value: StoryMO)

    @objc(removeStoriesObject:)
    @NSManaged public func removeFromStories(_ value: StoryMO)

    @objc(addStories:)
    @NSManaged public func addToStories(_ values: NSSet)

    @objc(removeStories:)
    @NSManaged public func removeFromStories(_ values: NSSet)

}
