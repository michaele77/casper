//
//  UserData.swift
//  Casper
//
//  Created by Michael Ershov on 2/5/23.
//
//  Defines the different Codable data types that will be persisted in storage for the iOS app. This will include things that should not change very often (like cached table addresses) as well as things that might change relatively frequently (such as the latest detected asset which should be persisted between app restarts).

import Foundation
import Photos

enum AssetType: Hashable, Codable {
    case unknown
    case image
    case video
}

struct Asset: Hashable, Codable {
    var localId: String = ""
    var type: AssetType = AssetType.unknown
    var creationTime: Date = Date(timeIntervalSince1970: TimeInterval(0))
    var xDimension: Int = -1
    var yDimension: Int = -1
    var duration: TimeInterval?
}

// Photo library metadata that can be changed quite frequently.
struct AssetLibraryMetadata: Hashable, Codable {
    // When the last library scan was done.
    var last_modified_time: Date = Date(timeIntervalSince1970: 0)
    // Total number of assets at the given library scan.
    var total_asset_number: Int = -1
    // Last detected asset from Photo library scans.
    var last_detected_asset: Asset = Asset()
}

// Basic preferences that will be used to control app flow.
// These are expected to change rarely, most of these should be either constants that are initialized in-file, or vars that can be updated during app initialization, or in other edge-cases (should be described per preference).
struct UserPreferences: Hashable, Codable {
    // How often the asset library should be scanned for updated assets when Casper is the focused app, expressed in ms.
    var in_app_library_scan_period_ms: Int = 1000
    // How often the asset library should be scanned for updated assets when Casper is not the focused app, expressed in seconds, since it is expected that asset refreshers will take longer running in the background.
    var out_of_app_library_scan_period_seconds: Int = 5
}

class GlobalVars: ObservableObject {
    @Published var inAppTimerFiredCounter: Int = 0
}


// NOTE: This is probably not needed, nuke it!
class PhotoLibraryData: NSObject, NSCoding {
    // This is an array of the last few assets that were scanned out.
    var asset_array: Array<Asset>
    // When the last library scan was done.
    var last_modified_time: Date = Date(timeIntervalSince1970: 0)
    // Total number of assets at the given library scan.
    var total_asset_number: Int = -1
    // Last detected asset from Photo library scans.
    var last_detected_asset: Asset = Asset()
    
    required init?(coder aDecoder: NSCoder) {
        asset_array = aDecoder.decodeObject(forKey: "asset_array") as? Array<Asset> ?? Array<Asset>()
        last_modified_time = aDecoder.decodeObject(forKey: "last_modified_time") as? Date ?? Date(timeIntervalSince1970: 0)
        total_asset_number = aDecoder.decodeObject(forKey: "total_asset_number") as? Int ?? -1
        last_detected_asset = aDecoder.decodeObject(forKey: "last_detected_asset") as? Asset ?? Asset()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(asset_array, forKey: "asset_array")
        aCoder.encode(last_modified_time, forKey: "last_modified_time")
        aCoder.encode(total_asset_number, forKey: "total_asset_number")
        aCoder.encode(last_detected_asset, forKey: "last_detected_asset")
    }
}

class PhotoAsset: NSObject, NSCoding {
    var localId: String
    var type: PHAssetMediaType
    var xDimension: Int
    var yDimension: Int
    var creationTime: Date
    var duration: TimeInterval
    
    override init() {
        localId = ""
        type = .unknown
        xDimension = -1
        yDimension = -1
        creationTime = Date(timeIntervalSince1970: TimeInterval(0))
        duration = .zero
    }
    
    init(localId: String, type: PHAssetMediaType, xDimension: Int, yDimension: Int, creationTime: Date, duration: TimeInterval) {
        self.localId = localId
        self.type = type
        self.xDimension = xDimension
        self.yDimension = yDimension
        self.creationTime = creationTime
        self.duration = duration
    }
    
    required init?(coder aDecoder: NSCoder) {
        localId = aDecoder.decodeObject(forKey: "local_id") as? String ?? ""
        // The PHAssetMediaType enum is stored as an integer in storage.
        let typeInteger = aDecoder.decodeInteger(forKey: "type_as_int") as Int
        type = PHAssetMediaType(rawValue: typeInteger) ?? .unknown
        xDimension = aDecoder.decodeInteger(forKey: "x_dimension") as Int
        yDimension = aDecoder.decodeInteger(forKey: "y_dimension") as Int
        // Dates and time intervals are stored as doubles representing seconds since 1970s in storage.
        let creationTimeAsDoubleSince1970 = aDecoder.decodeDouble(forKey: "creation_time_as_double") as Double
        creationTime = Date(timeIntervalSince1970: creationTimeAsDoubleSince1970)
        let durationAsDouble = aDecoder.decodeDouble(forKey: "duration_as_double") as Double
        duration = TimeInterval(durationAsDouble)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(localId, forKey: "local_id")
        aCoder.encode(xDimension, forKey: "x_dimension")
        aCoder.encode(yDimension, forKey: "y_dimension")
        let typeAsInt = type.rawValue
        aCoder.encode(typeAsInt, forKey: "type_as_int")
        let creationTimeAsDouble = Double(creationTime.timeIntervalSince1970)
        aCoder.encode(creationTimeAsDouble, forKey: "creation_time_as_double")
        let durationAsDouble = Double(duration)
        aCoder.encode(durationAsDouble, forKey: "duration_as_double")
    }
}

//class PhotoAsset: NSObject, NSCoding, Decodable {
//    var localId: String = ""
//    var type: PHAssetMediaType = .unknown
//    var xDimension: Int = -1
//    var yDimension: Int = -1
//    var creationTime: Date = Date(timeIntervalSince1970: TimeInterval(0))
//    var duration: TimeInterval = .zero
//    
//    required init(from decoder: Decoder) throws {
//        localId = decoder.decode(String.self, forKey: "local_id") as? String ?? ""
//        // The PHAssetMediaType enum is stored as an integer in storage.
//        let typeInteger = aDecoder.decodeObject(forKey: "type_as_int") as? Int ?? 0
//        type = PHAssetMediaType(rawValue: typeInteger) ?? .unknown
//        xDimension = aDecoder.decodeObject(forKey: "x_dimension") as? Int ?? -1
//        yDimension = aDecoder.decodeObject(forKey: "y_dimension") as? Int ?? -1
//        // Dates and time intervals are stored as doubles representing seconds since 1970s in storage.
//        let creationTimeAsDoubleSince1970 = aDecoder.decodeObject(forKey: "creation_time_as_double") as? Double ?? 0.0
//        creationTime = Date(timeIntervalSince1970: creationTimeAsDoubleSince1970)
//        let durationAsDouble = aDecoder.decodeObject(forKey: "duration_as_double") as? Double ?? 0.0
//        duration = TimeInterval(durationAsDouble)
//    }
//    
//    func encode(with aCoder: NSCoder) {
//        aCoder.encode(localId, forKey: "local_id")
//        aCoder.encode(xDimension, forKey: "x_dimension")
//        aCoder.encode(yDimension, forKey: "y_dimension")
//        let typeAsInt = type.rawValue
//        aCoder.encode(typeAsInt, forKey: "type_as_int")
//        let creationTimeAsDouble = Double(creationTime.timeIntervalSince1970)
//        aCoder.encode(creationTimeAsDouble, forKey: "creation_time_as_double")
//        let durationAsDouble = Double(duration)
//        aCoder.encode(durationAsDouble, forKey: "duration_as_double")
//    }
//}

class UserDataManager {
    let prefs = UserDefaults.standard
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // last_modified_date_double (Date <--> double)
    func getLastModifiedDate() -> Date {
        return Date(timeIntervalSince1970: prefs.double(forKey: "last_modified_date_double"))
    }
    func setLastModifiedDate(last_modified_date: Date) {
        prefs.set(last_modified_date.timeIntervalSince1970, forKey: "last_modified_date_double")
    }
    
    // total_asset_number (int <--> int)
    func getTotalAssetNumber() -> Int {
        return prefs.integer(forKey: "last_modified_time")
    }
    func setTotalAssetNumber(total_asset_number: Int) {
        prefs.set(total_asset_number, forKey: "last_modified_time")
    }
    
    // last_detected_asset (PhotoAsset <--> PhotoAsset)
    // This includes a convenience store: the PhotoAsset.localId string
    // Calling the top-level setLastDetectedAsset will also call setLastDetectedAssetLocalId.
    func getLastDetectedAsset() -> PhotoAsset {
        let decoded  = prefs.data(forKey: "last_detected_asset")
        let decodedLastDetectedAsset = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! PhotoAsset
        return decodedLastDetectedAsset
    }
    func setLastDetectedAsset(last_detected_asset: PhotoAsset) {
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: last_detected_asset)
        prefs.set(encodedData, forKey: "last_detected_asset")
        setLastDetectedAssetLocalId(last_detected_asset_local_id: last_detected_asset.localId)
    }
    func getLastDetectedAssetLocalId() -> String {
        return prefs.string(forKey: "last_detected_asset_local_id")!
    }
    func setLastDetectedAssetLocalId(last_detected_asset_local_id: String) {
        prefs.set(last_detected_asset_local_id, forKey: "last_detected_asset_local_id")
    }
}

