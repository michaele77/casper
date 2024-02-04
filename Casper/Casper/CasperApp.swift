//
//  CasperApp.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI
import BackgroundTasks
import CoreData

@main
struct CasperApp: App {
    // DataManagers
    let statsManager = StatsManager()
    
    init() {
        // Track how often the app is launched.
        print("launching...has launched --> \(statsManager.getTimesAppHasLaunched()) times")
        statsManager.incrementTimesAppHasLaunched()
        statsManager.resetLocalTimerCounter()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
