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
    @FetchRequest(sortDescriptors: []) var fetchedStats: FetchedResults<Statistics>
    @ObservedObject var globalVars: GlobalVars
    let imageManager = ImageDataManager()
    // This is assumed to be non-nil by the code (something should always be injected).
    var assetLibraryHelper: AssetLibraryHelper?
    
    @State private var showNewSessionCreationPage: Bool = false
    @State private var assetMap: [String: Asset] = [:]
    @AppStorage("last_detected_asset_local_id", store: .standard) var mostRecentAssetLocalId: String = "EMPTY"
    @State private var shownImage: UIImage = UIImage(systemName: "questionmark")!
    @AppStorage("stats-timer_counter", store: .standard) var timerCounter: Int = -1
    @AppStorage("stats-times_app_has_launched", store: .standard) var timesAppHasLaunched: Int = -1
    
    
    
    var body: some View {
        ZStack {
            Color(.systemGray2)
                .ignoresSafeArea()
            
            VStack() {
                Text("Sessions!")
                
                Button(action: {
                    assetMap = assetLibraryHelper!.readFromPhotoLibrary()
                }) {
                    Text("read photo library + print it")
                }
                .foregroundColor(Color.red)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Text("size of assetmap: \(assetMap.count)")
                
                Button(action: {
                    shownImage = assetLibraryHelper!.printSingleAsset(assetMap: assetMap)
                }) {
                    Text("print some image")
                }
                .foregroundColor(Color.green)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Button(action: {
                    shownImage = assetLibraryHelper!.fetchPhotoWithLocalId(localId: imageManager.getLastDetectedAsset().localId)
                }) {
                    Text("print latest image")
                }
                .foregroundColor(Color.yellow)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Text("DEBUG INFO: [timer counter] --> \(globalVars.inAppTimerFiredCounter)")
                Text("PERSISTED COUNTERS: [timer counter] --> \(timerCounter), [times app has launched] --> \(timesAppHasLaunched)")
                
                Image(uiImage: assetLibraryHelper!.fetchPhotoWithLocalId(localId: imageManager.getLastDetectedAsset().localId))
                    .resizable()
                    .frame(width: 100, height: 100) // Set the desired width and height
                    .scaledToFit() // Maintain the aspect ratio of the image
                
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

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        let assetLibraryHelper = AssetLibraryHelper()
        SessionView(globalVars: GlobalVars(), assetLibraryHelper: assetLibraryHelper)
    }
}
