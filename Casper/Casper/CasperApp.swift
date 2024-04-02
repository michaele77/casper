//
//  CasperApp.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI
import BackgroundTasks
import CoreData

@main
struct CasperApp: App {
    // DataManagers
    let statsManager = StatsManager()
    let imageManager = ImageDataManager()
    
    // Sets up any states that are expected to be non-nill or non-zero in the app.
    // Do it here instead of having random setup logic spread out throughout the app.
    private func setupDefaultStatesForFirstLaunch() {
        if imageManager.getTotalAssetNumber() == 0 {
            let currentNumberOfAssets = AssetLibraryHelper.shared.fetchTotalNumberOfAssets()
            print("<<CasperApp>> HAD NO ASSETS BEFORE, Resetting to \(currentNumberOfAssets)")
            imageManager.setTotalAssetNumber(totalAssetNumber: currentNumberOfAssets)
        }
    }
    
    // Increment counters that track relevant startup data.
    private func incrementStartupCounters() {
        statsManager.incrementTimesAppHasLaunched()
        statsManager.resetLocalTimerCounter()
        statsManager.resetSecondsSpentScanningAssets()
        statsManager.resetSecondsSpentProcessingQueue()
        print("<<CasperApp>> launching...has launched --> \(statsManager.getTimesAppHasLaunched()) times")
    }
    
    init() {
        setupDefaultStatesForFirstLaunch()
        incrementStartupCounters()
        QueueProcessors.shared.launchAsyncTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
