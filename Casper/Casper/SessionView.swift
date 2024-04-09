//
//  SessionView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI
import Photos
import BackgroundTasks

struct SessionView: View {
    @State private var showNewSessionCreationPage: Bool = false
    @State private var assetMap: [String: Asset] = [:]
    @State private var shownImage: UIImage = UIImage(systemName: "questionmark")!
    @State private var isToggled = false
    
    // These need to be bound to AppsStorage to make sure that the view is updated whenever the values are updated.
    @AppStorage(AppConstants.kTimerCounterKey, store: .standard) var timerCounter: Int = -1
    @AppStorage(AppConstants.kTimesAppHasLaunchedKey, store: .standard) var timesAppHasLaunched: Int = -1
    @AppStorage(AppConstants.kLastDetectedAsssetLocalIdKey, store: .standard) var mostRecentAssetLocalId: String = "EMPTY"
        
    // DataManagers
    let statsManager = StatsManager()
    let imageManager = ImageDataManager()
    
    var body: some View {
        ZStack {
            Color(.systemGray2)
                .ignoresSafeArea()
            
            VStack() {
                
                // Large red "Kill" button
                Button(action: {
                    // Kill the app. Make it quit too so that the user doesn't think it's still running
                    print("KILLING THE APP BECAUSE THE USER REQUESTED IT!")
                    exit(-1)
                }) {
                    Text("KILL")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .frame(width: 400, height: 100)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                
                // Large red "Kill" button
                Button(action: {
                    // Kill the app. Make it quit too so that the user doesn't think it's still running
                    print("<<RESET>> resetting pqueue and asset buffer....")
                    ProcessingQueue.shared.debugUseOnlyResetProcessingQueue()
                    imageManager.setAssetBuffer(assetBuffer: [PhotoAsset]())
                }) {
                    Text("Reset Processing Queue Storage?")
                        .font(.custom("San Francisco", size: 20))
                        .foregroundColor(.white)
                        .frame(width: 400, height: 80)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Toggle("Queue Processing is On?", isOn: $isToggled)
                    .font(.custom("San Francisco", size: 20))
                    .onChange(of: isToggled) { newValue in
                        print("Toggle switched to \(newValue)")
                        ProcessingQueue.shared.setIsProcessingAllowed(is_allowed: newValue)
                        print("isProcessingAllowed is switched to \(ProcessingQueue.shared.getIsProcessingAllowed() ? "true" : "false")")
                    }
                            .padding()
                
                
                Spacer().frame(height:50)
                
                
                Text("Sessions!")
                    .foregroundColor(Color(.systemBlue))
                    .bold(false)
                    .font(.custom("Copperplate", size: 50))
                
                Button(action: {
                    assetMap = AssetLibraryHelper.shared.readFromPhotoLibrary()
                }) {
                    Text("read photo library + print it")
                }
                .foregroundColor(Color.red)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Text("size of assetmap: \(assetMap.count)")
                
                Button(action: {
                    shownImage = AssetLibraryHelper.shared.fetchPhotoWithLocalId(localId: imageManager.getLastDetectedAsset().localId)
                }) {
                    Text("print latest image with localID of \(imageManager.getLastDetectedAsset().localId)")
                }
                .foregroundColor(Color.yellow)
                .bold(false)
                .font(.custom("Copperplate", size: 10))
                
                Image(uiImage: AssetLibraryHelper.shared.fetchPhotoWithLocalId(localId: imageManager.getLastDetectedAsset().localId))
                    .resizable()
                    .frame(width: 200, height: 200) // Set the desired width and height
                    .scaledToFit() // Maintain the aspect ratio of the image
                
                Button(action: {
                    self.showNewSessionCreationPage.toggle()
                }) {
                    Text("+")
                }
                .sheet(isPresented: $showNewSessionCreationPage) {
                    SessionCreationView()
                }
                .frame(width: 100, height: 100)
                .bold(false)
                .font(.custom("Copperplate", size: 100))
                .foregroundColor(Color.white)
                .background(Color(.systemBlue))
                .clipShape(Circle())
                .offset(x:0, y:50)
            }
        }
    }
}

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
    }
}
