//
//  UserData.swift
//  Casper
//
//  Created by Michael Ershov on 2/5/23.
//
//  Defines the different Codable data types that will be persisted in storage for the iOS app. This will include things that should not change very often (like cached table addresses) as well as things that might change relatively frequently (such as the latest detected asset which should be persisted between app restarts).

import Foundation

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
    // When the last time AssetMetadata was updated.
    var last_modified_time: Date = Date(timeIntervalSince1970: TimeInterval(0))
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

