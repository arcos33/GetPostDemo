//
//  User+CoreDataProperties.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/4/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var phone_number: String?
    @NSManaged public var name: String?
    @NSManaged public var zipcode: String?
    @NSManaged public var email: String?
    @NSManaged public var tenant: String?
    @NSManaged public var first_name: String?
    @NSManaged public var last_name: String?
    @NSManaged public var profile_photo: String?

}
