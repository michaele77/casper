//
//  UserData.swift
//  Casper
//
//  Created by Michael Ershov on 2/5/23.
//
//  Defines the different Codable data types that will be persisted in storage for the iOS app. This will include things that should not change very often (like cached table addresses) as well as things that might change relatively frequently (such as the latest detected asset which should be persisted between app restarts).

import Foundation
import Photos



class AppParams {
    // We will be initializing all of the parameters here and hardcoding it.
    // TODO: Ideally, these parameters should probably either be: 1) fetched from the server and based on the current App version or 2) stored in some other plist or other sort of file so they are centrally located.
    // Timer periodicity in seconds.
    static public let kTimerPeriodSeconds: Double = 5
    // Number of assets to scan back per scanning trip.
    static public let kScanLastNAssets: Int = 10
    // Maximum number of assets to scan back to. Anything before this will not be considered by the App.
    static public let kMaxAssetsToScan: Int = 100
    // Asset dequeue periodicity. This basically defines the asset upload rate.
    // A periodicity of 10s --> 360 assets uploaded per hour.
    // A peruodicity of 1s --> 3600 assets uploaded per hour.
    static public let kQueueProcessingPeriodicitySeconds: Double = 2
}

class AppConstants {
    // Define all of the constant user default name mappings here. That way, they wont be spread all over the place in code.
    static public let kLastDetectedAsssetLocalIdKey: String = "image_manager-last_detected_asset_local_id"
    static public let kLastModifiedDateDoubleKey: String = "image_manager-last_modified_date_double"
    static public let kTotalAssetNumberKey: String = "image_manager-total_asset_number"
    static public let kLastDetetedAssetKey: String = "image_manager-last_detected_asset"
    static public let kRecentAssetsBufferKey: String = "image_manager-recent_assets_buffer"
    static public let kTimesAppHasLaunchedKey : String = "stats-times_app_has_launched"
    static public let kTimerCounterKey: String = "stats-timer_counter"
    static public let kLocalTimerCounter: String = "stats-local_timer_counter"
    static public let kHasCreatedAccountKey : String = "user_data-has_created_account"
    static public let kFirstNameKey: String = "user_data-first_name"
    static public let kLastNameKey: String = "user_data-last_name"
    static public let kProcessingQueueKey: String = "data-processing_queue"
    static public let kTimeProcessingQueueKey: String = "stats-processing_queue_seconds"
    static public let kTimeScanningAssetsKey: String = "stats-asset_scanning_seconds"
}

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

class PhotoAsset: NSObject, NSCoding {
    var localId: String
    var type: PHAssetMediaType
    var xDimension: Int
    var yDimension: Int
    var creationTime: Date
    var duration: TimeInterval
    static private let kDefaultId = "DEFAULT_ID"
    
    override init() {
        localId = PhotoAsset.kDefaultId
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
    
    func isDefault() -> Bool {
        if self.localId == PhotoAsset.kDefaultId {
            return true
        }
        return false
    }
}

class ImageDataManager {
    private let prefs = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // kLastModifiedDateDoubleKey (Date <--> double)
    func getLastModifiedDate() -> Date {
        return Date(timeIntervalSince1970: prefs.double(forKey: AppConstants.kLastModifiedDateDoubleKey))
    }
    func setLastModifiedDate(last_modified_date: Date) {
        prefs.set(last_modified_date.timeIntervalSince1970, forKey: AppConstants.kLastModifiedDateDoubleKey)
    }
    
    // totalAssetNumber (int <--> int)
    func getTotalAssetNumber() -> Int {
        return prefs.integer(forKey: AppConstants.kTotalAssetNumberKey)
    }
    func setTotalAssetNumber(totalAssetNumber: Int) {
        prefs.set(totalAssetNumber, forKey: AppConstants.kTotalAssetNumberKey)
    }
    
    // lastDetectedAsset (PhotoAsset <--> PhotoAsset)
    // This includes a convenience store: the PhotoAsset.localId string
    // Calling the top-level setLastDetectedAsset will also call setLastDetectedAssetLocalId.
    func getLastDetectedAsset() -> PhotoAsset {
        let decoded  = prefs.data(forKey: AppConstants.kLastDetetedAssetKey)
        if decoded == nil{
            print("No such lastDetectedAsset, returning default PhotoAsset")
            return PhotoAsset()
        }
        // TODO: Need to figure out a way to fix these compilation warnings with unarchiveObject and archivedData; can be deprecated at any time really.
        let decodedLastDetectedAsset = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! PhotoAsset
        return decodedLastDetectedAsset
    }
    func setLastDetectedAsset(lastDetectedAsset: PhotoAsset) {
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: lastDetectedAsset)
        prefs.set(encodedData, forKey: AppConstants.kLastDetetedAssetKey)
        setLastDetectedAssetLocalId(lastDetectedAsssetLocalId: lastDetectedAsset.localId)
    }
    func getLastDetectedAssetLocalId() -> String {
        return prefs.string(forKey: AppConstants.kLastDetectedAsssetLocalIdKey) ?? "NOT_SET!!!"
    }
    func setLastDetectedAssetLocalId(lastDetectedAsssetLocalId: String) {
        prefs.set(lastDetectedAsssetLocalId, forKey: AppConstants.kLastDetectedAsssetLocalIdKey)
    }
    
    // image buffer, an array of localIDs
    func getAssetBuffer() -> [PhotoAsset] {
        let decoded  = prefs.data(forKey: AppConstants.kRecentAssetsBufferKey)
        if decoded == nil {
            return [PhotoAsset]()
        }
        return NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [PhotoAsset]
    }
    func setAssetBuffer(assetBuffer: [PhotoAsset]) {
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: assetBuffer)
        prefs.set(encodedData, forKey: AppConstants.kRecentAssetsBufferKey)
    }
}

// TODO: Make a .super() class called "DataManager" or something that implements the basic int/string encodings and will initialize these prefs/encoders/decoder things
class StatsManager {
    private let stats = UserDefaults.standard
    
    // stats-times_app_has_launched (Int <--> Int)
    func incrementTimesAppHasLaunched() {
        incrementCounter(counter_name: AppConstants.kTimesAppHasLaunchedKey)
    }
    func getTimesAppHasLaunched() -> Int {
        return stats.integer(forKey: AppConstants.kTimesAppHasLaunchedKey)
    }
    
    // This is a global counter, that just keeps incrementing for all times that the timer has went off.
    // stats-timer_counter (Int <--> Int)
    func incrementTimerCounter() {
        incrementCounter(counter_name: AppConstants.kTimerCounterKey)
    }
    func getTimerCounter() -> Int {
        return stats.integer(forKey: AppConstants.kTimerCounterKey)
    }
    
    // As opposed to stats-timer_counter, this is instead a counter that counts the amount of times the timer has gone off during this time that the app has launched. "Local" here refers to temporal locality, not spatial.
    // Because we reset this on each launch of the App, a resetter function is very useful.
    // stats-timer_counter (Int <--> Int)
    func incrementLocalTimerCounter() {
        incrementCounter(counter_name: AppConstants.kLocalTimerCounter)
    }
    func getLocalTimerCounter() -> Int {
        return stats.integer(forKey: AppConstants.kLocalTimerCounter)
    }
    func resetLocalTimerCounter() {
        stats.set(0, forKey: AppConstants.kLocalTimerCounter)
    }
    func getElapsedHoursBasedOnLocalCounter() -> Double {
        return Double(getLocalTimerCounter()) * AppParams.kTimerPeriodSeconds / 3600
    }
    func incrementSecondsSpentProcessingQueue(additionalSeconds: Double) {
        let currentSecondsSpent = getSecondsSpentProcessingQueue()
        stats.set(additionalSeconds + currentSecondsSpent, forKey: AppConstants.kTimeProcessingQueueKey)
    }
    func resetSecondsSpentProcessingQueue() {
        stats.set(0.0, forKey: AppConstants.kTimeProcessingQueueKey)
    }
    func getSecondsSpentProcessingQueue() -> Double {
        return stats.double(forKey: AppConstants.kTimeProcessingQueueKey)
    }
    func incrementSecondsSpentScanningAssets(additionalSeconds: Double) {
        let currentSecondsSpent = getSecondsSpentScanningAssets()
        stats.set(additionalSeconds + currentSecondsSpent, forKey: AppConstants.kTimeScanningAssetsKey)
    }
    func resetSecondsSpentScanningAssets() {
        stats.set(0.0, forKey: AppConstants.kTimeScanningAssetsKey)
    }
    func getSecondsSpentScanningAssets() -> Double {
        return stats.double(forKey: AppConstants.kTimeScanningAssetsKey)
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
        hasCreatedAccount = userData.bool(forKey: AppConstants.kHasCreatedAccountKey)
        print("has created account? \(hasCreatedAccount)")
    }
    
    // user_data-first_name (String <--> String)
    func getFirstName() -> String {
        if !hasCreatedAccount {
            return "NOT_CREATED_ACCOUNT"
        }
        return userData.string(forKey: AppConstants.kFirstNameKey) ?? "FIRST_NOONNNEE"
    }
    func setFirstName(first_name: String) {
        markAccountAsCreated()
        userData.set(first_name, forKey: AppConstants.kFirstNameKey)
    }
    
    // user_data-last_name (String <--> String)
    func getLastName() -> String {
        if !hasCreatedAccount {
            return "NOT_CREATED_ACCOUNT"
        }
        return userData.string(forKey: AppConstants.kLastNameKey) ?? "LAST_NOONNNEE"
    }
    func setLastName(last_name: String) {
        markAccountAsCreated()
        userData.set(last_name, forKey: AppConstants.kLastNameKey)
    }
    
    // Returns whether the account has been created yet.
    func hasUserCreatedAccount() -> Bool {
        return userData.bool(forKey: AppConstants.kHasCreatedAccountKey)
    }
    
    // Private funcs:
    private func markAccountAsCreated() {
        if hasCreatedAccount {
            return
        }
        userData.set(true, forKey: AppConstants.kHasCreatedAccountKey)
        hasCreatedAccount = true
    }
}

// This class manages the asset queue. This class attempts to make a thread-safe interface layer between a UserDefault array in persistance and what appears to be a queue externally.
class ProcessingQueue {
    static let shared = ProcessingQueue()
    // Private initializer to prevent creating multiple instances
    private init() {}

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queueLock = NSLock()
    
    private let storage = UserDefaults.standard
    
//    private var semaphore = false
    private var lockTimeMicros = 0
    private let lockTimeoutSeconds = 10
    private var assetArray: [PhotoAsset] = []

    // Enqueues the input array of PhotoAssets.
    func enqueue(newAssets: [PhotoAsset]) {
        print("<<USER_DATA>> VV_LOCKING_VV")
        queueLock.lock()
        writeQueueToStorage(queue: getQueueFromStorage() + newAssets)
        queueLock.unlock()
        print("<<USER_DATA>> VV_UNLOCKED_VV")
    }
    
    // Dequeues the first asset from the processing queue and returns it.
    // If the queue has nothing to dequeue, a default asset is returned.
    func dequeue() -> PhotoAsset {
        print("<<USER_DATA>> VV_LOCKING_VV")
        queueLock.lock()
        // Load current array representing the queue and remove the first asset.
        var currentAssets = getQueueFromStorage()
        if currentAssets.count == 0 {
            queueLock.unlock()
            print("<<USER_DATA>> VV_UNLOCKED_VV")
            return PhotoAsset()
        }
        let firstAsset = currentAssets.removeFirst()

        // Write the new combined array to storage.
        writeQueueToStorage(queue: currentAssets)
        queueLock.unlock()
        print("<<USER_DATA>> VV_UNLOCKED_VV")

        // Return the removed asset.
        return firstAsset
    }
    
    // Returns the size of the queue in storage.
    func size() -> Int {
        let currentAssets = storage.array(forKey: AppConstants.kProcessingQueueKey) as? [PhotoAsset] ?? []
        return currentAssets.count
    }

    // Get the array representing the queue and return it.
    // If it doesn't exist, return an empty array.
    private func getQueueFromStorage() -> [PhotoAsset] {
        print("<<USER_DATA>> -->>>>  GETTING QUEUE!")        
        let decoded  = storage.data(forKey: AppConstants.kProcessingQueueKey)
        if decoded == nil {
            print("<<USER_DATA>> No processing queue, returning an empty array")
            return [PhotoAsset]()
        }
        let queue = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [PhotoAsset]
        print("<<USER_DATA>>        - queue size: \(queue.count)")
        return queue
    }
    
    private func writeQueueToStorage(queue: [PhotoAsset]) {
        print("<<USER_DATA>> <<<<<-- RETURNING QUEUE!")
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: queue)
        storage.set(encodedData, forKey: AppConstants.kProcessingQueueKey)
        print("<<USER_DATA>>        - queue size: \(queue.count)")
    }
}
