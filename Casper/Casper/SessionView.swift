//
//  SessionView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI
import Photos

struct SessionView: View {
    @State private var showNewSessionCreationPage: Bool = false
    @State private var assetMap: [String: Asset] = [:]
    @State private var shownImage: UIImage = UIImage(systemName: "house")!
    
    // This is assumed to be non-nil by the code (something should always be injected).
    var assetLibraryHelper: AssetLibraryHelper?
    
    init(assetLibraryHelper: AssetLibraryHelper) {
        self.assetLibraryHelper = assetLibraryHelper
    }
    
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
                    shownImage = assetLibraryHelper!.fetchLatestAsset()
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

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        let assetLibraryHelper = AssetLibraryHelper()
        SessionView(assetLibraryHelper: assetLibraryHelper)
    }
}
