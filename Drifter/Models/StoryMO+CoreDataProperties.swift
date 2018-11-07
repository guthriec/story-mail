//
//  StoryMO+CoreDataProperties.swift
//  Drifter
//
//  Created by Chris on 11/6/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//

import Foundation
import CoreData


extension StoryMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryMO> {
        return NSFetchRequest<StoryMO>(entityName: "Story")
    }

    @NSManaged public var id: String?
    @NSManaged public var isArchived: Bool
    @NSManaged public var lastUpdated: NSDate?
    @NSManaged public var pages: NSOrderedSet?
    @NSManaged public var contributors: NSSet?

}

// MARK: Generated accessors for pages
extension StoryMO {

    @objc(insertObject:inPagesAtIndex:)
    @NSManaged public func insertIntoPages(_ value: PageMO, at idx: Int)

    @objc(removeObjectFromPagesAtIndex:)
    @NSManaged public func removeFromPages(at idx: Int)

    @objc(insertPages:atIndexes:)
    @NSManaged public func insertIntoPages(_ values: [PageMO], at indexes: NSIndexSet)

    @objc(removePagesAtIndexes:)
    @NSManaged public func removeFromPages(at indexes: NSIndexSet)

    @objc(replaceObjectInPagesAtIndex:withObject:)
    @NSManaged public func replacePages(at idx: Int, with value: PageMO)

    @objc(replacePagesAtIndexes:withPages:)
    @NSManaged public func replacePages(at indexes: NSIndexSet, with values: [PageMO])

    @objc(addPagesObject:)
    @NSManaged public func addToPages(_ value: PageMO)

    @objc(removePagesObject:)
    @NSManaged public func removeFromPages(_ value: PageMO)

    @objc(addPages:)
    @NSManaged public func addToPages(_ values: NSOrderedSet)

    @objc(removePages:)
    @NSManaged public func removeFromPages(_ values: NSOrderedSet)

}

// MARK: Generated accessors for contributors
extension StoryMO {

    @objc(addContributorsObject:)
    @NSManaged public func addToContributors(_ value: UserMO)

    @objc(removeContributorsObject:)
    @NSManaged public func removeFromContributors(_ value: UserMO)

    @objc(addContributors:)
    @NSManaged public func addToContributors(_ values: NSSet)

    @objc(removeContributors:)
    @NSManaged public func removeFromContributors(_ values: NSSet)

}
