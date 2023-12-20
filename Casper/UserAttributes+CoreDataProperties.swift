//
//  UserAttributes+CoreDataProperties.swift
//  Casper
//
//  Created by Michael Ershov on 12/18/23.
//
//

import Foundation
import CoreData


extension UserAttributes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserAttributes> {
        return NSFetchRequest<UserAttributes>(entityName: "UserAttributes")
    }

    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var hasSignedUp: Bool

}

extension UserAttributes : Identifiable {

}
