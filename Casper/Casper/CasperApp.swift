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
    @Environment(\.scenePhase) private var phase
    // TODO: Get rid of persistance controller, dont need it now with user defaults.
    let persistenceController = PersistenceController.shared
    let statsManager = StatsManager()
    
    init() {
        // Track how often the app is launched.
        print("launching...has launched --> \(statsManager.timesAppHasLaunched()) times")
        statsManager.incrementTimesAppHasLaunched()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
