//
//  ProcessingQueueView.swift
//  Casper
//
//  Created by Michael Ershov on 4/2/24.
//

import SwiftUI

class ClickGenerator {
    var prevId:String = "none"
    var isFirst = true
    func clickIfProcessed(newId: String) {
        if prevId != newId {
            prevId = newId
            
            // Do not click the haptic feedback the first time we update the view
            if isFirst {
                isFirst = false
                return
            }
            
            // Perform haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

struct ProcessingQueueView: View {
    @AppStorage(AppConstants.kProcessingQueueWriteCounterKey, store: .standard) var queueWriteCounter: Int = -1
    let xSize: CGFloat = 500
    let ySize: CGFloat = 500
    let clicky = ClickGenerator()

    func getShortDateTime(time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Define your desired date format
        return formatter.string(from: time)
    }
    
    var body: some View {
        VStack() {
            Text("Processing Queue Write Counter: \(queueWriteCounter)")
            VStack {
                HStack() {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.blue)
                            .frame(width: 25, height: 400)
                        Text("Asset to process")
                            .rotationEffect(Angle(degrees: -90))
                            .foregroundColor(Color.black)
                            .bold(false)
                            .font(.custom("San Francisco", size: 15))
                    }
                    
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 10) {
                            ForEach(ProcessingQueue.shared.latest_10_processing_queue_assets, id: \.self) { photoAsset in
                                VStack() {
                                    Text(getShortDateTime(time: photoAsset.creationTime))
                                    Image(uiImage: AssetLibraryHelper.shared.fetchPhotoWithLocalId(localId: photoAsset.localId))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: xSize, height: ySize)
                                    Text("Type: \(photoAsset.type.rawValue)")
                                }
                            }
                        }
                        .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

struct ProcessingQueueView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingQueueView()
    }
}
