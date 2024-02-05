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
    let queueManager = ProcessingQueueManager.shared

    public func fetchAndPersistLatestAsset() throws {
        print("timer fired @ \(String(describing: time))")
        // Let's read from the photo library.
        guard let asset: PhotoAsset = fetchMetadataForLatestAsset() else {
            throw CasperErrors.readError("Latest asset could not be fetched.")
        }

        print("Persisted asset with creation time of \(asset.creationTime)")
        imageManager.setLastDetectedAsset(lastDetectedAsset: asset)
    }
    
    // This function scans through the latest until one of the following conditions are met:
    // 1) One of the IDs are the kLastDetetedAssetKey
//    public func scanThroughLatestAssets() throws {
//        
//    }
    
    // TODO: MASSIVE BUG -- This does not support looking at DELETED photos. So if someone deletes a photo all bets are off. Pretty massive bug lol but there are ways around it, just increases the scope and complexity here quite a bit.
    // Function to scan the photo library, detect new photo assets, then add them to the processing queue in storage.
    public func addNewImagesToQueue() throws {
        let currentNumberOfAssets = fetchTotalNumberOfAssets()
        let previousNumberOfAssets = imageManager.getTotalAssetNumber()
        if currentNumberOfAssets <= previousNumberOfAssets {
            if currentNumberOfAssets == previousNumberOfAssets {
                print("<<ASSET_LIBRARY_UTILS>> No new assets! Do nothing.")
                return
            } else {
                print("<<ASSET_LIBRARY_UTILS>> We lost assets! This case is not handled, do nothing EXCEPT for resetting number of total assets in storage.")
                imageManager.setTotalAssetNumber(totalAssetNumber: currentNumberOfAssets)
                return
            }
        }

        // If we are here, we must have new assets. Fetch them and remember to persist the number of assets read.
        let numberOfNewAssets = currentNumberOfAssets - previousNumberOfAssets
        let fetchedAssets = try fetchMetadataForNLastestAssets(numberOfNewAssets: numberOfNewAssets)
        
        print("<<ASSET_LIBRARY_UTILS>> Do Enqueing logic here!!")
        queueManager.enqueue(newAssets: fetchedAssets)
        
        imageManager.setTotalAssetNumber(totalAssetNumber: currentNumberOfAssets)
    }
    
    public func fetchTotalNumberOfAssets() -> Int {
        // Request authorization to access photos
        var photoCount = 0
        var hasRequestFinished = false
        print("<<1>>")
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                print("<<2>>")
                // Access to photos is granted
                
                // Fetch all photos from the camera roll
                let fetchOptions = PHFetchOptions()
                let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                
                // Get the count of photos
                photoCount = allPhotos.count
                
                // Print or use the photo count as needed
                print("Number of photos: \(photoCount)")
                print("<<3>>")
                hasRequestFinished = true
            } else {
                // Access to photos is not granted
                print("Access to photos is not authorized.")
                hasRequestFinished = true
            }
        }
        
        while !hasRequestFinished { }
        print("<<4>> photos: \(photoCount)")
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

    public func fetchMetadataForNLastestAssets(numberOfNewAssets: Int) throws -> [PhotoAsset] {
        // Sort the images by descending creation date and fetch the last 10.
        // TODO: This does not fetch live photos, as far as i am aware. Will need to fix that.
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = numberOfNewAssets
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d OR mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)

        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)

        // If the fetch result is less than expected, return with an error.
        if fetchResult.count != numberOfNewAssets {
            throw CasperErrors.readError("Unexpected number of assets fetched, expected \(numberOfNewAssets) but only got \(fetchResult.count).")
        }
        
        var fetchedAssetArray: [PhotoAsset] = []

        // Loop through the fetched assets
            for index in 0 ..< fetchResult.count {
                print("<<ASSET_LIBRARY_UTILS>> Fetch latest N assets: at index - \(index) - ")
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
}
