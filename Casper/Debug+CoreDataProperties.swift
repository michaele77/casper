//
//  Debug+CoreDataProperties.swift
//  Casper
//
//  Created by Michael Ershov on 12/18/23.
//
//

import Foundation
import CoreData


extension Debug {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Debug> {
        return NSFetchRequest<Debug>(entityName: "Debug")
    }

    @NSManaged public var pingCounter: Int64
    @NSManaged public var timerCounter: Int64

}

extension Debug : Identifiable {

}
