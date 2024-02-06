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
    }
}

struct MainTabsView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabsView()
    }
}
