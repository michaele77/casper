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

    // TODO: These don't seem to work, make them!
    public var safeFirstName: String {
        firstName ?? "UnknownFirstName"
    }
    
    public var safeLastName: String {
        lastName ?? "UnknownLastName"
    }
}

extension UserAttributes : Identifiable {

}
