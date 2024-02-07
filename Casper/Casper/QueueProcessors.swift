//
//  QueueProcessors.swift
//  Casper
//
//  Created by Michael Ershov on 2/5/24.
//

import Foundation

class QueueProcessors {
    static let shared = QueueProcessors()
    private init() {}
    
    let scanningThread = DispatchQueue(label: "com.processingQueue.scanningThread")
    let processingThread = DispatchQueue(label: "com.processingQueue.processingThread")
    let lock = NSLock()
    let statsManager = StatsManager()
    
    // This variable is used for the sole purpoe of updating views whenever a thread fires.
    // All the real work is done here, so aside from user interactions, we should only ever need to update views after we've processed some work here.
    var threadPoker: Int = 0
    
    public func launchAsyncTasks() {
        print("<<LAUNCH_TASKS>> Launching Asset scanner")
        self.asyncAssetScanner()
        print("<<LAUNCH_TASKS>> Launching queue processor")
        self.asyncQueueProcessor()
        print("<<LAUNCH_TASKS>> Done launching tasks")
    }
    
    // Because this class is threaded, we need to increment threadPoker in a thread-safe way.
    private func incrementThreadPoker() {
        lock.lock()
        self.threadPoker += 1
        lock.unlock()
    }
    
    // This function calls an infinite loop that continuously scans the asset library.
    // Make sure that the active time of the processing queue remains small.
    private func asyncAssetScanner() {
        scanningThread.async {
            while true {
                // Start of processing work.
                print("<<ASSET_SCANNER>> Asset scanning starting.")
                self.statsManager.incrementAllTimerCounters()
                do {
                    try AssetLibraryHelper.shared.scanAndEnqueueNewAssets()
                } catch {
                    print("Error occured in addNewImagesToQueue: \(error.localizedDescription)")
                }
                print("<<ASSET_SCANNER>> Asset scanning is done!")
                
                // We can also fetch and persist the latest asset scanned. This will update our front page.
                do {
                    try AssetLibraryHelper.shared.fetchAndPersistLatestAsset()
                } catch {
                    print("Error occured in fetchAndPossiblyPersistLatestAsset: \(error.localizedDescription)")
                }
                // End of processing work.
                
                // Sleep for a set amount of time and increment the threadPoker.
                self.incrementThreadPoker()
                Thread.sleep(forTimeInterval: AppParams.kTimerPeriodSeconds)
            }
        }
        
    }
    
    // This function calls an infinite loop that continuously processes the queue.
    // Make sure that the active time of the processing queue remains small.
    private func asyncQueueProcessor() {
        processingThread.async {
            while true {
                // Start of processing work.
                print("<<QUEUE_PROCESSOR>> BackgroundProcessor starting.")
                let asset = ProcessingQueue.shared.dequeue()
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
                // End of processing work.
                
                // Sleep for a set amount of time and increment the threadPoker.
                self.incrementThreadPoker()
                Thread.sleep(forTimeInterval: AppParams.kQueueProcessingPeriodicitySeconds)
            }
        }
        
    }
}
