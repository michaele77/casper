//
//  ProcessingQueueView.swift
//  Casper
//
//  Created by Michael Ershov on 4/2/24.
//

import SwiftUI

struct ProcessingQueueView: View {
    @AppStorage(AppConstants.kProcessingQueueWriteCounterKey, store: .standard) var queueWriteCounter: Int = -1
    let xSize: CGFloat = 300
    let ySize: CGFloat = 300
    
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 20) {
                ForEach(ProcessingQueue.shared.latest_10_processing_queue_assets, id: \.self) { photoAsset in
                    Image(uiImage: AssetLibraryHelper.shared.fetchPhotoWithLocalId(localId: photoAsset.localId))
                        .resizable()
                        .scaledToFit()
                        .frame(width: xSize, height: ySize)
                }
            }
            .padding()
        }
//        ZStack {
//            Color(.systemGray2)
//                .ignoresSafeArea()
//            
//            VStack() {
//                Text("Processing Queue here!")
//                
//                Text("queue write counter: \(queueWriteCounter)")
//                
//                Text("-----")
//                
//                Image(uiImage: AssetLibraryHelper.shared.fetchPhotoWithLocalId(localId: ProcessingQueue.shared.latest_10_processing_queue_assets[0].localId))
//                    .resizable()
//                    .frame(width: xSize, height: ySize) // Set the desired width and height
//                    .scaledToFit() // Maintain the aspect ratio of the image
//                    .offset(x: 100, y: 100)
//                
//                Text("-----")
//                
//                Image(uiImage: AssetLibraryHelper.shared.fetchPhotoWithLocalId(localId: ProcessingQueue.shared.latest_10_processing_queue_assets[1].localId))
//                    .resizable()
//                    .frame(width: xSize, height: ySize) // Set the desired width and height
//                    .scaledToFit() // Maintain the aspect ratio of the image
//                    .offset(x: 100, y: 200)
//                
//                Text("-----")
//                
//                Image(uiImage: AssetLibraryHelper.shared.fetchPhotoWithLocalId(localId: ProcessingQueue.shared.latest_10_processing_queue_assets[2].localId))
//                    .resizable()
//                    .frame(width: xSize, height: ySize) // Set the desired width and height
//                    .scaledToFit() // Maintain the aspect ratio of the image
//                    .offset(x: 100, y: 300)
//                
//                Text("-----")
//                
//                Image(uiImage: AssetLibraryHelper.shared.fetchPhotoWithLocalId(localId: ProcessingQueue.shared.latest_10_processing_queue_assets[3].localId))
//                    .resizable()
//                    .frame(width: xSize, height: ySize) // Set the desired width and height
//                    .scaledToFit() // Maintain the aspect ratio of the image]
//                    .offset(x: 100, y: 400)
//                
//                Text("-----")
//                
//            }
//        }
    }
}

struct ProcessingQueueView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingQueueView()
    }
}
