//
//  SessionView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI
import Photos

enum AssetType {
    case image
    case video
}

struct Asset {
    var localId: String
    var type: AssetType
    var creationTime: Date
    var xDimension: Int
    var yDimension: Int
    var duration: Int?
}

struct SessionView: View {
    @State private var showNewSessionCreationPage: Bool = false
    @State private var assetMap: [String: Asset] = [:]
    @State private var shownImage: UIImage = UIImage(systemName: "house")!
    
    var body: some View {
        ZStack {
            Color(.systemGray2)
                .ignoresSafeArea()
            
            VStack() {
                Text("Sessions!")
                
                Button(action: {
                    assetMap = readFromPhotoLibrary()
                }) {
                    Text("read photo library + print it")
                }
                .foregroundColor(Color.red)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Text("size of assetmap: \(assetMap.count)")
                
                Button(action: {
                    shownImage = printSingleAsset(assetMap: assetMap)
                }) {
                    Text("print some image")
                }
                .foregroundColor(Color.green)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Button(action: {
                    shownImage = fetchLatestAsset()
                }) {
                    Text("print latest image")
                }
                .foregroundColor(Color.yellow)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Image(uiImage: shownImage)
                
                Button(action: {
                    self.showNewSessionCreationPage.toggle()
                }) {
                    Text("+")
                }
                .sheet(isPresented: $showNewSessionCreationPage) {
                    // Step 4
                    SessionCreationView()
                }
                .frame(width: 100, height: 100)
                .bold(false)
                .font(.custom("Copperplate", size: 100))
                .foregroundColor(Color.white)
                .background(Color(.systemBlue))
                .clipShape(Circle())
                .offset(x:0, y:250)
            }
        }
    }
}

private func readFromPhotoLibrary() -> [String: Asset] {
    let semaphore = DispatchSemaphore(value: 0)
    var allSortedAssets: [Asset] = []
    var allAssetMap: [String: Asset] = [:]
    print("<<0>>")
    PHPhotoLibrary.requestAuthorization { status in
        print(status)
        print("<<1>>")
        if status == .authorized {
            var counter = 0
            var image_map: [String: Date] = [:]
            
            print("Fetching images....")
            
            let assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil)
            let pictures =
            assets.enumerateObjects {
                (object, _, _) in
                counter += 1
                image_map[object.localIdentifier] = object.creationDate
                let tempAsset = Asset(localId: object.localIdentifier,
                                      type: AssetType.image,
                                      creationTime: object.creationDate ?? Date(timeIntervalSince1970: TimeInterval(10)),
                                      xDimension: object.pixelWidth,
                                      yDimension: object.pixelHeight,
                                      duration: nil)
                allSortedAssets.append(tempAsset)
                allAssetMap[tempAsset.localId] = tempAsset
//                print(object)
//                print("Asset info: x = \(object.pixelWidth), y = \(object.pixelHeight), duration = \(object.duration), creation date = \(object.creationDate)")
                
            }
            print("Done with images, asset total is \(counter)")
            
            print("Fetching videos....")
            var video_map: [String: Date] = [:]
            let video_assets = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: nil)
            assets.enumerateObjects {
                (object, _, _) in
                counter += 1
                video_map[object.localIdentifier] = object.creationDate
            }
            
            print("<<2>>")
            print("Done with videos, asset total is \(counter)")
            print("<<3>>")
            semaphore.signal()
        }
        
        print("<<4>>")
        print("<<5>>")
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

private func printSingleAsset(assetMap: [String: Asset]) -> UIImage {
    // Try printing just a single image
    let printAsset = assetMap["3C750FBD-1D56-410D-9AC5-058483F73BF7/L0/001"]
    var localIdentifiers: [String] = []
    localIdentifiers.append(printAsset!.localId)
    
    let options = PHFetchOptions()
    let results = PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: options)
    let manager = PHImageManager.default()
    var returnImage = UIImage()
    results.enumerateObjects { (thisAsset, _, _) in
        manager.requestImage(for: thisAsset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: nil, resultHandler: {(thisImage, _) in
            returnImage = thisImage!
        })
    }
    return returnImage
}

private func fetchLatestAsset() -> UIImage {
    // Sort the images by descending creation date and fetch the last 10
    let imagesToFetch = 10
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
    fetchOptions.fetchLimit = imagesToFetch

    // Fetch the image assets
    let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)

    // If the fetch result isn't empty, proceed with the image request
    if fetchResult.count < 1 {
        return UIImage(systemName: "question")!
    }
    var fetchedImages: [UIImage] = fetchSomePhotos(numberOfImages: imagesToFetch, fetchResult: fetchResult)
    let returnImage: [UIImage] = fetchedImages.suffix(1)
    return returnImage[0]
}

private func fetchSomePhotos(
    numberOfImages: Int,
    fetchResult: PHFetchResult<PHAsset>) -> [UIImage] {
        
    var imagesToReturn: [UIImage] = []
    
    for _ in 1...numberOfImages {
        imagesToReturn.append(fetchPhotoAtIndex(
            index: 0, fetchResult: fetchResult))
    }
    return imagesToReturn
}

private func fetchPhotoAtIndex(
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

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
    }
}
