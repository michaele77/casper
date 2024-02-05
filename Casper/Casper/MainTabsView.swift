//
//  MainTabsView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI

struct MainTabsView: View {    
    @State private var default_tab = 2
    // This needs to be created here becuase we are using this in the main timer callback.
    @StateObject var asset_library_helper = AssetLibraryHelper.shared
    
    // DataManagers
    let imageManager = ImageDataManager()
    let statsManager = StatsManager()

    // This timer will actually fire in the background even if the app is not open, so as long as the app is running, this seems like it will still work; doesn't seem *particularly* deterministic, though.
    // TODO: Obviously, if the app gets shut down or crashes, the timer will no longer fire. This is ok for now, but really we eventually want to have a more consistent way of generating background tasks even if the app gets closed.
    let timer = Timer.publish(every: AppParams.kTimerPeriodSeconds, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection:$default_tab) {
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.3.sequence.fill")
                }.tag(1)
            SessionView()
                .tabItem {
                    Label("Sessions", systemImage: "network")
                }.tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(3)
            KillView()
                .tabItem {
                    Label("KILL", systemImage: "figure.wave.circle.fill")
                }.tag(4)
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { time in
            statsManager.incrementAllTimerCounters()
            // TODO: We can probably get rid of the fetchAndPersistLatestAsset bit now...
            do {
                try AssetLibraryHelper.shared.fetchAndPersistLatestAsset()
            } catch {
                print("Error occured in fetchAndPossiblyPersistLatestAsset: \(error.localizedDescription)")
            }
            
            do {
                try AssetLibraryHelper.shared.addNewImagesToQueue()
            } catch {
                print("Error occured in addNewImagesToQueue: \(error.localizedDescription)")
            }
                
        }
    }
}

struct MainTabsView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabsView()
    }
}
