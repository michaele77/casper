//
//  MainTabsView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI

struct MainTabsView: View {    
    @State private var default_tab = 1

    var body: some View {
        TabView(selection:$default_tab) {
            SessionView()
                .tabItem {
                    Label("Sessions", systemImage: "network")
                }.tag(1)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(2)
            ProcessingQueueView()
                .tabItem {
                    Label("Queue", systemImage: "photo.stack.fill")
                }.tag(3)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct MainTabsView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabsView()
    }
}
