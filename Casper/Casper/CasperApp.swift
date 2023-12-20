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
    let persistenceController = PersistenceController.shared
    
    init() {
        // Let's increment a counter for counting a statistic.
        // NOTE: @FetchRequest apparently doesn't work if not inside of a view (which at this point, we are not). So we'll need to do a manual fetch request here.
        
        let fetchRequest : NSFetchRequest<Statistics> = Statistics.fetchRequest()
        fetchRequest.sortDescriptors = []
        do {
            let fetchedStats = try persistenceController.container.viewContext.fetch(fetchRequest)
            let stats: Statistics
            if fetchedStats.count == 0 {
                // If the app has never been launched before, we'll need to initiate all of the core data singleton entities.
                // TODO: Initialize all of the other singleton entities like Debug and Metadata. Also, extract this to a singleton entity class manager or something.
                stats = Statistics(context: persistenceController.container.viewContext)
                stats.timesAppHasLaunched = 0
                stats.pingCounter = 0
                stats.timerCounter = 0
                print("CREATING FIRST STATS ARRAY FOR THE FIRST TIME!!")
            } else {
                stats = fetchedStats.first!
                print("RELOADING STATS! HERE IS THE NUM OF TIMES LAUNCHED --> \(fetchedStats.first!.timesAppHasLaunched)")
            }
            fetchedStats.first!.timesAppHasLaunched += 1
            try? persistenceController.container.viewContext.save()
            
        } catch  {
            print("OOPSIE ERRORRRR")
            print(error.localizedDescription)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: phase) { windowPhase in
            // Everytime the app moves to the background, the peristenceController will automatically save its state.
            try? persistenceController.container.viewContext.save()
        }
    }
}
