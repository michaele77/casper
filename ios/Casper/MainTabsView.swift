//
//  MainTabsView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI

struct MainTabsView: View {    
    @State private var default_tab = 2
    @EnvironmentObject var webSocketManager: WebSocketManager

    var body: some View {
        TabView(selection:$default_tab) {
            SessionView()
                .tabItem {
                    Label("Sessions", systemImage: "network")
                }.tag(1)
            ManagementView()
                .tabItem {
                    Label("Management", systemImage: "cat")
                }.tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(3)
            ProcessingQueueView()
                .tabItem {
                    Label("Queue", systemImage: "photo.stack.fill")
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
