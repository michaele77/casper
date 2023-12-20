//
//  Statistics+CoreDataProperties.swift
//  Casper
//
//  Created by Michael Ershov on 12/20/23.
//
//

import Foundation
import CoreData


extension Statistics {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Statistics> {
        return NSFetchRequest<Statistics>(entityName: "Statistics")
    }

    @NSManaged public var timesAppHasLaunched: Int64
    @NSManaged public var pingCounter: Int64
    @NSManaged public var timerCounter: Int64

}

extension Statistics : Identifiable {

}
