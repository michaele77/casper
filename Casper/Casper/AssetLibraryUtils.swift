//
//  AssetLibraryUtils.swift
//  Casper
//
//  Created by Michael Ershov on 2/5/23.
//
//  Stateless class that should be initialized in a view that needs it. Provides an interface for reading and writing to the asset (photo) library.

import Foundation
import Photos
import SwiftUI

// This is a stateless class to help retrieve stored photos and videos. Prefer to use the static singleton.
class AssetLibraryHelper: ObservableObject {
    static let shared = AssetLibraryHelper()
    // Private initializer to prevent creating multiple instances
    private init() {}

    // DataManagers
    let imageManager = ImageDataManager()

    public func fetchAndPersistLatestAsset() throws {
        print("timer fired @ \(String(describing: time))")
        // Let's read from the photo library.
        guard let asset: PhotoAsset = fetchMetadataForLatestAsset() else {
            throw CasperErrors.readError("Latest asset could not be fetched.")
        }

        print("Persisted asset with creation time of \(asset.creationTime)")
        imageManager.setLastDetectedAsset(lastDetectedAsset: asset)
    }
    
    // Function to scan the photo library, detect new photo assets, then add them to the processing queue in storage.
    public func scanAndEnqueueNewAssets() throws {
        // 1) Retreieve the localIDs for the N last images, sorted by *creationTime*, call is currBuffer.
        // 2) Read back the prevBuffer from storage.
        // 3) Do a diff of the N images; we are only interested in any new images in the  buffer. NOTE: The 2 buffers can be of different length!
        // 4) (optional) can check the total asset number as well. If this doesn't match what we expect, then we can log it, but there's not much we can do; it just means photos were deleted beyond the "horizon" of our scan. After all, someone can delete the first photo out of 100k assets, we would have a mismatch, but we don't really care.
        // 5) Persist currBuffer
        // 6) Enqueue the new assets into the processingQueue
        // NOTE: the above procedure gets us a nice property: Photos taken by the iphone will show up at the top. I *think* that airdropped photos will also have a new creationTime corresponding to when they were recieved on the device, but this may be wrong. Either way, this sort of sorting actually favors the app's functionality EVEN IF airdropped photos keep their old creationTime.
        // TODO: Confirm this functionalility with airdropped photos! Either way, probably not a huge deal (given the reasoning above).
        
        // 1)
        let assetBuffer: [PhotoAsset] = try fetchMetadataForNLastestAssets(numberOfAssetsToFetch: AppParams.kMaxAssetsToScan)
        
        // 2)
        var prevAssetBuffer: [PhotoAsset] = imageManager.getAssetBuffer()
        
        // 3)
        var newAssets: [PhotoAsset] = try! diffOldAndNewAssetBuffers(oldBuffer: prevAssetBuffer, newBuffer: assetBuffer)
        
        // 4) TODO: Implement this optional check? Maybe?
        
        // Early out if no difference.
        if newAssets.isEmpty {
            print("<<ASSET_LIBRARY_UTILS>> -- <<SCANNER>> No difference detected, continuing...")
            return
        }
        
        // 5)
        imageManager.setAssetBuffer(assetBuffer: assetBuffer)
        
        // 6)
        print("<<ASSET_LIBRARY_UTILS>> Do Enqueing \(newAssets.count) more assets!")
        ProcessingQueue.shared.enqueue(newAssets: newAssets)
    }
    
    public func fetchTotalNumberOfAssets() -> Int {
        // Request authorization to access photos
        var photoCount = 0
        var hasRequestFinished = false
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Fetch all photos from the camera roll
                let fetchOptions = PHFetchOptions()
                let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                
                // Get the count of photos
                photoCount = allPhotos.count
                
                // Print or use the photo count as needed
                print("<<ASSET_LIBRARY_UTILS>> Total Number of photos: \(photoCount)")
                hasRequestFinished = true
            } else {
                // Access to photos is not granted
                print("<<ASSET_LIBRARY_UTILS>> Access to photos is not authorized.")
                hasRequestFinished = true
            }
        }

        // Block execution until the async fetch request has finished.
        while !hasRequestFinished { }
        return photoCount
    }
    
    public func fetchMetadataForLatestAsset() -> PhotoAsset? {
        // Sort the images by descending creation date and fetch the last 10.
        let imagesToFetch = 1
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = imagesToFetch

        // Fetch the image assets
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)

        // If the fetch result is empty, return with a nil.
        if fetchResult.count < 1 {
            return nil
        }
        
        if fetchResult.firstObject == nil {
            return nil
        }
        
        return PHAssetToPhotoAsset(object: fetchResult.firstObject!)
    }

    public func fetchMetadataForNLastestAssets(numberOfAssetsToFetch: Int) throws -> [PhotoAsset] {
        // Sort the images by descending creation date and fetch the last 10.
        // TODO: This does not fetch live photos, as far as i am aware. Will need to fix that.
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = numberOfAssetsToFetch
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d OR mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)

        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        
        // If the fetch result is less than expected, return with an error.
        // (This can error if the account just doesn't have that many assets...
        if fetchResult.count != numberOfAssetsToFetch {
            print("Unexpected number of assets fetched, expected \(numberOfAssetsToFetch) but only got \(fetchResult.count).")
            // Let's do a last check that the total number of assets the device contains is not simply smaller than the number of assets that was requested.
            let fetchOptions = PHFetchOptions()
            let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
            if allPhotos.count != fetchResult.count || allPhotos.count >= numberOfAssetsToFetch {
                throw CasperErrors.readError("Unexpected number of assets fetched, expected \(numberOfAssetsToFetch) but only got \(fetchResult.count).")
            }
        }
        
        var fetchedAssetArray: [PhotoAsset] = []

        // Loop through the fetched assets
        let printEveryN = 50
        for index in 0 ..< fetchResult.count {
            if index % printEveryN == 0 {
                print("<<ASSET_LIBRARY_UTILS>> (PRINT EVERY \(printEveryN)) Fetch latest N assets: at index - \(index) - ")
                print("<<ASSET_LIBRARY_UTILS>> has creation time of \(String(describing: fetchResult[index].creationDate))")
            }
            fetchedAssetArray.append(PHAssetToPhotoAsset(object: fetchResult[index]))
        }
        
        return fetchedAssetArray
    }

    public func readFromPhotoLibrary() -> [String: Asset] {
        let semaphore = DispatchSemaphore(value: 0)
        var allSortedAssets: [Asset] = []
        var allAssetMap: [String: Asset] = [:]
        PHPhotoLibrary.requestAuthorization { status in
            print(status.rawValue)
            if status == .authorized {
                var counter = 0
                var imageMap: [String: Date] = [:]
                
                print("Fetching images....")
                let assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil)
                let pictures =
                assets.enumerateObjects {
                    (object, _, _) in
                    counter += 1
                    imageMap[object.localIdentifier] = object.creationDate
                    let tempAsset = Asset(localId: object.localIdentifier,
                                          type: AssetType.image,
                                          creationTime: object.creationDate ?? Date(timeIntervalSince1970: TimeInterval(10)),
                                          xDimension: object.pixelWidth,
                                          yDimension: object.pixelHeight,
                                          duration: nil)
                    allSortedAssets.append(tempAsset)
                    allAssetMap[tempAsset.localId] = tempAsset
                }
                print("Done with images, asset total is \(counter)")
                
                print("Fetching videos....")
                var videoMap: [String: Date] = [:]
                let videoAssets = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: nil)
                assets.enumerateObjects {
                    (object, _, _) in
                    counter += 1
                    videoMap[object.localIdentifier] = object.creationDate
                }
                print("Done with videos, asset total is \(counter)")
                semaphore.signal()
            }
            
            print("now let's sort the assets")
            allSortedAssets.sort(by: { (lhs, rhs) -> Bool in
                return lhs.creationTime < rhs.creationTime
            })
            print("Done sorting the assets")
            print("What were the most recent photos? ")
            print(allSortedAssets.suffix(20))
            print("let's look at a specific photo: ")
        }
        semaphore.wait()
        return allAssetMap
    }
    
    // RANDOM HELPER METHODS. May or may not be useful in the future.

    public func fetchSomePhotos(
        numberOfImages: Int,
        fetchResult: PHFetchResult<PHAsset>) -> [UIImage] {
            
        var imagesToReturn: [UIImage] = []
        
        for _ in 1...numberOfImages {
            imagesToReturn.append(fetchPhotoAtIndex(
                index: 0, fetchResult: fetchResult))
        }
        return imagesToReturn
    }

    public func fetchPhotoAtIndex(
        index: Int,
        fetchResult: PHFetchResult<PHAsset>) -> UIImage {
            
            // Note that if the request is not set to synchronous
            // the requestImageForAsset will return both the image
            // and thumbnail; by setting synchronous to true it
            // will return just the thumbnail
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            
            var returnImage: UIImage? =  nil
            // Perform the image request
            PHImageManager.default().requestImage(for: fetchResult.object(at: index) as PHAsset, targetSize: CGSize(width: 500.0, height: 500.0), contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
                returnImage = image!
            })
            return returnImage!
    }
    
    public func fetchPhotoWithLocalId(localId: String) -> UIImage {
        // Note that if the request is not set to synchronous
        // the requestImageForAsset will return both the image
        // and thumbnail; by setting synchronous to true it
        // will return just the thumbnail
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        let results = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: PHFetchOptions())
        let manager = PHImageManager.default()
        var returnImage = UIImage()
        results.enumerateObjects { (thisAsset, _, _) in
            manager.requestImage(for: thisAsset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: {(thisImage, _) in
                print("<<>> --> Image size: \(thisImage!.size)")
                print("<<>> --> Image scale: \(thisImage!.scale)")
                returnImage = thisImage!
            })
        }
        return returnImage
    }
    
    // Private section.
    
    // Helper to unwrap a fetched PHImage into a Casper-friendly Asset struct.
    private func PHAssetToPhotoAsset(object: PHAsset) -> PhotoAsset {
        return PhotoAsset(localId: object.localIdentifier,
                          type: object.mediaType,
                          xDimension: object.pixelWidth,
                          yDimension: object.pixelHeight,
                          creationTime: object.creationDate ?? Date(timeIntervalSince1970: 0),
                          duration: object.duration)
    }
    
    // TODO: This function probably has bugs. It really needs tests (Will be easy to add). So add them!
    private func diffOldAndNewAssetBuffers(oldBuffer: [PhotoAsset], newBuffer: [PhotoAsset]) throws -> [PhotoAsset] {
        // Handle edge conditions.
        if oldBuffer.count == 0 {
            print("<<ASSET_LIBRARY_UTILS>> <<SCAN_DIFFER>> Returning the whole thing since the old buffer was never persisted")
            return newBuffer
        }
        if newBuffer.count == 0 {
            print("Apparently, all of the photos have been deleted...let's error here")
            throw CasperErrors.readError("We do not expect all of the photos to have been deleted...")
        }
        
        
        // To avoid bugs if the kMaxAssetsToScan parameter changes between persistances, truncate the buffers to match the minimum size.
        // The returned sort order is sorted as the most recent asset at index 0, so truncate the old assets from the back.
        // This will maintain correctness, and basically just assumes that kMaxAssetsToScan will never get super small relative to old sizes; even if it does, it should still work (maybe?)
        var countDifference = oldBuffer.count - newBuffer.count
        var trimmedOldBuffer = oldBuffer
        var trimmedNewBuffer = newBuffer
        if (countDifference > 0)  {
            // Means old > new, so need to cut off from the old.
            trimmedOldBuffer.removeLast(countDifference)
        } else if (countDifference < 0) {
            // Means new > old, so need to cut off from the new.
            trimmedNewBuffer.removeLast(-1*countDifference)
        }

        // We want to return items that ARE in the new buffer, but are NOT in the old buffer. Use a set to make this operation faster and more readable.
        var oldSet = Set<String>()
        for asset in trimmedOldBuffer {
            oldSet.insert(asset.localId)
        }
        
        var newAssets = [PhotoAsset]()
        let oldestCreationTimeFromBefore = trimmedOldBuffer.last!.creationTime
        for asset in trimmedNewBuffer {
            if !oldSet.contains(asset.localId) {
                if oldestCreationTimeFromBefore > asset.creationTime {
                    print("<<ASSET_LIBRARY_UTILS>> <<SCAN_DIFFER>> Old asset, ignore")
                    continue
                }
                print("<<ASSET_LIBRARY_UTILS>> <<SCAN_DIFFER>> Found difference for asset of local ID \(asset.localId) that was created at \(asset.creationTime)")
                newAssets.append(asset)
            }
        }
        
        return newAssets
        
    }
}
