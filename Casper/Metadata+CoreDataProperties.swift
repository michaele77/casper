//
//  Metadata+CoreDataProperties.swift
//  Casper
//
//  Created by Michael Ershov on 12/18/23.
//
//

import Foundation
import CoreData


extension Metadata {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Metadata> {
        return NSFetchRequest<Metadata>(entityName: "Metadata")
    }


}

extension Metadata : Identifiable {

}
