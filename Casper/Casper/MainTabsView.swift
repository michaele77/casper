//
//  MainTabsView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI

struct MainTabsView: View {    
    @State private var default_tab = 2
    @StateObject var asset_library_helper = AssetLibraryHelper()
    let imageManager = ImageDataManager()
    let statsManager = StatsManager()

    // Create a timer that fires every 10 seconds. It will actually fire in the background even if the app is not open, so as long as the app is running, this seems like it will still work.
    // TODO: Obviously, if the app gets shut down or crashes, the timer will no longer fire. This is ok for now, but really we eventually want to have a more consistent way of generating background tasks even if the app gets closed.
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection:$default_tab) {
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.3.sequence.fill")
                }.tag(1)
            SessionView(assetLibraryHelper: asset_library_helper)
                .tabItem {
                    Label("Sessions", systemImage: "network")
                }.tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(3)
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { time in
            do {
                try asset_library_helper.fetchAndPossiblyPersistLatestAsset()
                statsManager.incrementAllTimerCounters()
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
        MainTabsView()
    }
}
