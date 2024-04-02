//
//  SettingsView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI

struct SettingsView: View {
    // DataManagers
    let statsManager = StatsManager()
    
    // These need to be bound to AppsStorage to make sure that the view is updated whenever the values are updated.
    
    // App parameters.
    
    
    // Counters.
    @AppStorage(AppConstants.kLastDetectedAsssetLocalIdKey, store: .standard) var lastDetectedLocalId: String = "EMPTY"
    @AppStorage(AppConstants.kLastModifiedDateDoubleKey, store: .standard) var lastModifiedDateDouble: Double = -1
    @AppStorage(AppConstants.kTotalAssetNumberKey, store: .standard) var totalAssetNumber: Int = -1
//    @AppStorage(AppConstants.kLastDetetedAssetKey, store: .standard) var lastDetectedAsset: PhotoAsset = PhotoAsset()
//    @AppStorage(AppConstants.kRecentAssetsBufferKey, store: .standard) var recentAssetsBuffer: [PhotoAsset]
    @AppStorage(AppConstants.kTimesAppHasLaunchedKey, store: .standard) var timesAppHasLaunched: Int = -1
    @AppStorage(AppConstants.kTimerCounterKey, store: .standard) var timerCounter: Int = -1
    @AppStorage(AppConstants.kLocalTimerCounter, store: .standard) var localTimerCounter: Int = -1
    @AppStorage(AppConstants.kHasCreatedAccountKey, store: .standard) var hasCreatedAccount: Bool = false
    @AppStorage(AppConstants.kFirstNameKey, store: .standard) var firstName: String = "EMPTY"
    @AppStorage(AppConstants.kLastNameKey, store: .standard) var lastName: String = "EMPTY"
    @AppStorage(AppConstants.kTimeProcessingQueueKey, store: .standard) var secondsInProcessingQueue: Double = -1
    @AppStorage(AppConstants.kTimeScanningAssetsKey, store: .standard) var secondsScanningAssets: Double = -1

    


    var body: some View {
        ZStack {
            Color(.systemGray2)
                .ignoresSafeArea()
            
            VStack() {
                Text("Counters, Parameters, and Settings!").font(.title)
                
                Spacer()
                Text("Timers & Common counters").font(.title)
                Text("[timerCounter]: \(timerCounter)")
                Text(String(format:"[localTimerCounter] --> %d ---> (hours elpased is: %.2f)", statsManager.getLocalTimerCounter(), statsManager.getElapsedHoursBasedOnLocalCounter()))
                Text("[timesAppHasLaunched]: \(timesAppHasLaunched)")
                Text("[secondsInProcessingQueue]: \(secondsInProcessingQueue)")
                Text("[secondsScanningAssets]: \(secondsScanningAssets)")
                
                Spacer()
                Text("App constants").font(.title)
                Text("[kTimerPeriodSeconds]: \(AppParams.kTimerPeriodSeconds)")
                Text("[kScanLastNAssets]: \(AppParams.kScanLastNAssets)")
                Text("[kMaxAssetsToScan]: \(AppParams.kMaxAssetsToScan)")
                Text("[kQueueProcessingPeriodicitySeconds]: \(AppParams.kQueueProcessingPeriodicitySeconds)")
                
                Spacer()
                Text("Buffer data").font(.title)
                Text("[lastModifiedDateDouble]: \(lastModifiedDateDouble)")
                Text("[totalAssetNumber]: \(totalAssetNumber)")
                Text("[lastDetectedLocalId]: \(lastDetectedLocalId)")
                
                Spacer()
                Text("Misc data").font(.title)
                Text("[hasCreatedAccount]: \(hasCreatedAccount ? "true" : "false")")
                Text("[firstName]: \(firstName)")
                Text("[lastName]: \(lastName)")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
