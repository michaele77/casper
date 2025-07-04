//
//  QueueProcessors.swift
//  Casper
//
//  Created by Michael Ershov on 2/5/24.
//

import Foundation

 func createUrlRequest(imageData: Data) -> URLRequest {
     let uploadImageEndpoint = AppConfig.kServerEndpoint + "/upload-image"
    // Create the request
    var request = URLRequest(url: URL(string: uploadImageEndpoint)!)
    request.httpMethod = "POST"
    let boundary = "---***---***---"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    // Generate body data for multipart/form-data
    var body = Data()
    // Append image data to the body
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"uploaded_image\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n".data(using: .utf8)!)

    body.append("--\(boundary)--\r\n".data(using: .utf8)!)

    // Set the HTTP body
    request.httpBody = body
    
    return request
}


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
            var counter = 0
            while true {
                counter += 1
                if counter % AppParams.self.kProcessingQueueViewUpdateMultiplier == 0 {
                    counter = 0
                    ProcessingQueue.shared.cacheLatest10Assets()
                }
                
                // Start of processing work.
                self.statsManager.incrementAllTimerCounters()
                ProcessingQueue.shared.incrementProcessingQueueWriteCounter()
                do {
                    let start_time = Date().timeIntervalSince1970
                    try AssetLibraryHelper.shared.scanAndEnqueueNewAssets()
                    self.statsManager.incrementSecondsSpentScanningAssets(additionalSeconds: Date().timeIntervalSince1970 - start_time)
                } catch {
                    print("Error occured in addNewImagesToQueue: \(error.localizedDescription)")
                }
                
                // We can also fetch and persist the latest asset scanned. This will update our front page.
                do {
                    try AssetLibraryHelper.shared.fetchAndPersistLatestAsset()
                } catch {
                    print("Error occured in fetchAndPossiblyPersistLatestAsset: \(error.localizedDescription)")
                }
                // End of processing work.
                
                // Sleep for a set amount of time and increment the threadPoker.
                self.incrementThreadPoker()
                Thread.sleep(forTimeInterval: AppParams.kAssetScanPeriodicitySeconds)
            }
        }
        
    }
    
    
    
    // This function calls an infinite loop that continuously processes the queue.
    // Make sure that the active time of the processing queue remains small.
    private func asyncQueueProcessor() {
        processingThread.async {
            while true {
                // Start of processing work.
                if !ProcessingQueue.shared.getIsProcessingAllowed() {
                    print("<<QUEUE_PROCESSOR>> Queue Processing is not allowed, sleeping...")
                    WebSocketManager.shared.sendMessage(message: "Not allowed to send image...")
                    Thread.sleep(forTimeInterval: AppParams.kQueueProcessingPeriodicitySeconds)
                    continue
                }
                print("<<QUEUE_PROCESSOR>> asyncQueueProcessor starting.")
                let start_time = Date().timeIntervalSince1970
                let asset = ProcessingQueue.shared.dequeue()
                self.statsManager.incrementSecondsSpentProcessingQueue(additionalSeconds: Date().timeIntervalSince1970 - start_time)
                if asset.isDefault() {
                    print("<<QUEUE_PROCESSOR>> No new assets to process!")
                } else {
                    print("<<QUEUE_PROCESSOR>> dequeued asset with localID of \(asset.localId)")
                    print("<<QUEUE_PROCESSOR>> sending request to server...")
                    // SIMULATING A REQUEST TO SERVER, TAKES SOME RANDOM AMOUNT OF TIME
                    Thread.sleep(forTimeInterval: Double.random(in: 0.5..<5))
                    
                    // Now we conver the UI image into either a JPG or a PNG.
                    let fullImage = AssetLibraryHelper.shared.fetchPhotoWithLocalId(localId: asset.localId)
                    
                    guard let imageData = fullImage.pngData() else {
                        print("          >>> <<<<<            ")
                        print("      >>>>>>> <<<<<<<<<<       ")
                        print("   >>>>>>>>>> <<<<<<<<<<<<<<   ")
                        print(">>>>>>>>>>>>> <<<<<<<<<<<<<<<<<")
                        print(">>> Image conversion failed <<<")
                        return
                    }
                    print("Data: \(imageData)")
                    
                    WebSocketManager.shared.sendMessage(message: ">>>> Start")
                    WebSocketManager.shared.sendImage(imageData: imageData)
                    WebSocketManager.shared.sendMessage(message: "End <<<<")
                    
                }
                // End of processing work.
                
                // Sleep for a set amount of time and increment the threadPoker.
                self.incrementThreadPoker()
                Thread.sleep(forTimeInterval: AppParams.kQueueProcessingPeriodicitySeconds)
            }
        }
    }
}
