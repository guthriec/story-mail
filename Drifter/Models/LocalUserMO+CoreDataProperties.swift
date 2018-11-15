//
//  LocalUserMO+CoreDataProperties.swift
//  Drifter
//
//  Created by Chris on 11/8/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//

import Foundation
import CoreData


extension LocalUserMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalUserMO> {
        return NSFetchRequest<LocalUserMO>(entityName: "LocalUser")
    }


}
