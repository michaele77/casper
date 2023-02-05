//
//  CasperApp.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI
import BackgroundTasks

@main
struct CasperApp: App {
    @Environment(\.scenePhase) private var phase
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: phase) {newPhase in
            switch newPhase {
            case .background: scheduleAppRefresh()
            default: break
            }
        }
        .backgroundTask(.appRefresh("casperPhotoCheckTask")) {
            print("<<1>>")
            scheduleAppRefresh()
            print("Doing a task!!!")
        }
        
    }
}

func scheduleAppRefresh() {
    print("<<2>>")
    let request = BGAppRefreshTaskRequest(identifier: "casperPhotoCheckTask")
    // Schedule a request in 10 seconds.
    print("Adding a schedule!")
    request.earliestBeginDate = .now
    print("what is now? \(request.earliestBeginDate)")
    request.earliestBeginDate = .now.addingTimeInterval(10)
    print("what is now + 10?? \(request.earliestBeginDate))")
    try? BGTaskScheduler.shared.submit(request)
}
