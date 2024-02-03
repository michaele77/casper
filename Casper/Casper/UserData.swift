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
        localId = "DEFAULT"
        type = .unknown
        xDimension = -1
        yDimension = -1
        creationTime = Date(timeIntervalSince1970: TimeInterval(0))
        duration = .infinity
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

class ImageDataManager {
    private let prefs = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

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
        if decoded == nil{
            print("No such lastDetectedAsset, returning default PhotoAsset")
            return PhotoAsset()
        }
        let decodedLastDetectedAsset = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! PhotoAsset
        return decodedLastDetectedAsset
    }
    func setLastDetectedAsset(last_detected_asset: PhotoAsset) {
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: last_detected_asset)
        prefs.set(encodedData, forKey: "last_detected_asset")
        setLastDetectedAssetLocalId(last_detected_asset_local_id: last_detected_asset.localId)
    }
    func getLastDetectedAssetLocalId() -> String {
        return prefs.string(forKey: "last_detected_asset_local_id") ?? "NOT_SET!!!"
    }
    func setLastDetectedAssetLocalId(last_detected_asset_local_id: String) {
        prefs.set(last_detected_asset_local_id, forKey: "last_detected_asset_local_id")
    }
}

// TODO: Make a .super() class called "DataManager" or something that implements the basic int/string encodings and will initialize these prefs/encoders/decoder things
class StatsManager {
    private let stats = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // stats-times_app_has_launched (Int <--> Int)
    func incrementTimesAppHasLaunched() {
        incrementCounter(counter_name: "stats-times_app_has_launched")
    }
    func getTimesAppHasLaunched() -> Int {
        return stats.integer(forKey: "stats-times_app_has_launched")
    }
    
    // This is a global counter, that just keeps incrementing for all times that the timer has went off.
    // stats-timer_counter (Int <--> Int)
    func incrementTimerCounter() {
        incrementCounter(counter_name: "stats-timer_counter")
    }
    func getTimerCounter() -> Int {
        return stats.integer(forKey: "stats-timer_counter")
    }
    
    // As opposed to stats-timer_counter, this is instead a counter that counts the amount of times the timer has gone off during this time that the app has launched. "Local" here refers to temporal locality, not spatial.
    // Because we reset this on each launch of the App, a resetter function is very useful.
    // stats-timer_counter (Int <--> Int)
    func incrementLocalTimerCounter() {
        incrementCounter(counter_name: "stats-local_timer_counter")
    }
    func getLocalTimerCounter() -> Int {
        return stats.integer(forKey: "stats-local_timer_counter")
    }
    func resetLocalTimerCounter() {
        stats.set(0, forKey: "stats-local_timer_counter")
    }
    
    // Because both timer counters should be incremented together, have a separate incrementor for that.
    func incrementAllTimerCounters() {
        incrementTimerCounter()
        incrementLocalTimerCounter()
    }
    
    // Private funcs:
    private func incrementCounter(counter_name: String) {
        stats.set(stats.integer(forKey: counter_name) + 1, forKey: counter_name)
    }
}

// Same as the other DataManagers, the only intricacy here is that we may very well read this data before the user has first logged in.
// Therefore, all returned data will be defaults until the user is created, at which point returned data will be "Real" data.
// We will not restrict setting new data here (even though we should, eventually).
// TODO: Consolidate all of the data into an external struct, and save the struct into one userDefault var.
class UserDataManager {
    private let userData = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var hasCreatedAccount = false
    
    init() {
        print("Starting up!")
        hasCreatedAccount = userData.bool(forKey: "user_data-has_created_account")
        print("has created account? \(hasCreatedAccount)")
    }
    
    // user_data-first_name (String <--> String)
    func getFirstName() -> String {
        if !hasCreatedAccount {
            return "NOT_CREATED_ACCOUNT"
        }
        return userData.string(forKey: "user_data-first_name") ?? "FIRST_NOONNNEE"
    }
    func setFirstName(first_name: String) {
        markAccountAsCreated()
        userData.set(first_name, forKey: "user_data-first_name")
    }
    
    // user_data-last_name (String <--> String)
    func getLastName() -> String {
        if !hasCreatedAccount {
            return "NOT_CREATED_ACCOUNT"
        }
        return userData.string(forKey: "user_data-last_name") ?? "LAST_NOONNNEE"
    }
    func setLastName(last_name: String) {
        markAccountAsCreated()
        userData.set(last_name, forKey: "user_data-last_name")
    }
    
    // Returns whether the account has been created yet.
    func hasUserCreatedAccount() -> Bool {
        return userData.bool(forKey: "user_data-has_created_account")
    }
    
    // Private funcs:
    private func markAccountAsCreated() {
        if hasCreatedAccount {
            return
        }
        userData.set(true, forKey: "user_data-has_created_account")
        hasCreatedAccount = true
    }
}

