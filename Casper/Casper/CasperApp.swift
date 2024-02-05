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
        print("<<CasperApp>> launching...has launched --> \(statsManager.getTimesAppHasLaunched()) times")
    }
    
    // TODO: This function will inevitably lead to stack overflow...make it iterative.
    private func recursiveBackgroundQueueProcessor() {
        print("<<QUEUE_PROCESSOR>> BackgroundProcessor starting.")
        let asset = ProcessingQueueManager.shared.dequeue()
        if asset.isDefault() {
            print("<<QUEUE_PROCESSOR>> No new assets to process!")
        } else {
            print("<<QUEUE_PROCESSOR>> dequeued asset with localID of \(asset.localId)")
            print("<<QUEUE_PROCESSOR>> sending request to server...")
            // TODO: Obviously, replace this for a stub to the real server.
            // SIMULATING A REQUEST TO SERVER, TAKES SOME RANDOM AMOUNT OF TIME
            Thread.sleep(forTimeInterval: Double.random(in: 0.5..<5))
            print("<<QUEUE_PROCESSOR>> request sent!")
        }
        
        
        DispatchQueue.global().async {
            // Call the function recursively after some delay
            DispatchQueue.main.asyncAfter(deadline: .now() + AppParams.kQueueProcessingPeriodicitySeconds) {
                recursiveBackgroundQueueProcessor()
            }
        }
        
    }
    
    init() {
        setupDefaultStatesForFirstLaunch()
        incrementStartupCounters()
        print("<<CasperApp>> BEFORE tasks)")
        recursiveBackgroundQueueProcessor()
        print("<<CasperApp>> AFTER tasks)")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
