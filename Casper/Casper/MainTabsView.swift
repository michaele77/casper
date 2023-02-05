//
//  MainTabsView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI

struct MainTabsView: View {
    @State private var default_tab = 2
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    
    var body: some View {
        
        
        TabView(selection:$default_tab) {
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "list.dash")
                }.tag(1)
            SessionView()
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
            print("timer fired @ \(time)")
        }
    }
}

struct MainTabsView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabsView()
    }
}
