//
//  MainTabsView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI

struct MainTabsView: View {
    // NOTE(mershov): We can try updating this to be a pure binding, then make the variable in the sessionView (or one of the other views) the @State view
    @StateObject var globalVars: GlobalVars = GlobalVars()
    
    @State private var default_tab = 2
    @StateObject var asset_library_helper = AssetLibraryHelper()

    // Create a timer that fires every 10 seconds.
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection:$default_tab) {
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "list.dash")
                }.tag(1)
            SessionView(globalVars: globalVars, assetLibraryHelper: asset_library_helper)
                .tabItem {
                    Label("Sessions", systemImage: "list.dash")
                }.tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "list.dash")
                }.tag(3)
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { time in
            do {
                try asset_library_helper.fetchAndPossiblyPersistLatestAsset()
                globalVars.inAppTimerFiredCounter += 1
            } catch {
                // TODO(mershov): Ideally, an error at this point should probably be logged or persisted somehow.
                // For now, no need to do anything with this error.
                print("Error occured in fetchAndPossiblyPersistLatestAsset: \(error.localizedDescription)")
            }
                
        }
    }
}

struct MainTabsView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabsView(globalVars: GlobalVars())
    }
}
