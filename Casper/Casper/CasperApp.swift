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
//    init() {
//        print("<<&&>> Launching App!!!")
//        BGTaskScheduler.shared.register(forTaskWithIdentifier: "casperPhotoCheckTask", using: nil) { task in
//             self.handleRepeatingBackgroundTask(task: task as! BGAppRefreshTask)
//        }
//        BGTaskScheduler.shared.register(forTaskWithIdentifier: "photoTask2", using: nil) { task in
//             self.handleRepeatingBackgroundTask(task: task as! BGAppRefreshTask)
//        }
//        print("<<&&>> registered tasks!!!")
//    }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) private var phase
    let persistenceController = PersistenceController.shared
    
    // NOTE(mershov): We can try updating this to be a pure binding, then make the variable in te sessionView (or one of the other views) the @State view
    @State var globalVars: GlobalVars = GlobalVars()
    
    

    // Register background task handler
//    BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.repeatingBackgroundTask", using: nil) { task in
//        // Perform the background task here
//        self.handleRepeatingBackgroundTask(task: task as! BGAppRefreshTask)
//    }
    

    var body: some Scene {
        WindowGroup {
            ContentView(globalVars: $globalVars)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: phase) {newPhase in
            switch newPhase {
            case .background: scheduleAppRefresh()
            case .active: scheduleActiveAppRefresh()
            default: break
            }
        }
//        .backgroundTask(.appRefresh("casperPhotoCheckTask")) {
//            print("<<1>>")
//            scheduleAppRefresh()
//            globalVars.tasksCounter += 1
//            print("Doing a task!!!")
//        }
        
    }
    
    func handleRepeatingBackgroundTask(task: BGAppRefreshTask) {
        // Perform the actual task
        print("Background task executed.")

        // Complete the task
        task.setTaskCompleted(success: true)
    }
    
    // NOTE(MERSHOV): This probably doesn't work on a simulator, try incrementing some globals and printing that and seeing if it works on-device.
    func scheduleAppRefresh() {
        print("<<2>>")
        globalVars.inactiveBackgroundCounter += 1
        let request = BGAppRefreshTaskRequest(identifier: "casperPhotoCheckTask")
        // Schedule a request in 10 seconds.
        print("Adding a schedule!")
        request.earliestBeginDate = .now
        print("what is now? \(request.earliestBeginDate)")
        request.earliestBeginDate = .now.addingTimeInterval(15)
        print("what is now + 15?? \(request.earliestBeginDate))")
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("DIDNT WORK!!! Error: \(error)")
        }
    }
    
    func scheduleActiveAppRefresh() {
        print("<<3>>")
        globalVars.activeBackgroundCounter += 1
        let request = BGAppRefreshTaskRequest(identifier: "casperPhotoCheckTask")
        // Schedule a request in 10 seconds.
        print("Adding a schedule!")
        request.earliestBeginDate = .now
        print("what is now? \(request.earliestBeginDate)")
        request.earliestBeginDate = .now.addingTimeInterval(5)
        print("what is now + 5?? \(request.earliestBeginDate))")
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("DIDNT WORK!!! Error: \(error)")
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // Register background task handler
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        print("<<&&>> Launching App!!!")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "casperPhotoCheckTask", using: nil) { task in
             self.handleRepeatingBackgroundTask(task: task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "photoTask2", using: nil) { task in
             self.handleRepeatingBackgroundTask(task: task as! BGAppRefreshTask)
        }
        print("<<&&>> registered tasks!!!")

        return true
    }
    
    func scheduleAppRefresh() {
        print("<<222>>")
//        globalVars.inactiveBackgroundCounter += 1
        let request = BGAppRefreshTaskRequest(identifier: "casperPhotoCheckTask")
        // Schedule a request in 10 seconds.
        print("Adding a schedule!")
        request.earliestBeginDate = .now
        print("what is now? \(request.earliestBeginDate)")
        request.earliestBeginDate = .now.addingTimeInterval(15)
        print("what is now + 15?? \(request.earliestBeginDate))")
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("DIDNT WORK!!! Error: \(error)")
        }
    }

    func handleRepeatingBackgroundTask(task: BGAppRefreshTask) {
        // Perform the actual task
        print("Background task executed.")
        
//        globalVars.tasksCounter += 1
        scheduleAppRefresh()

        // Complete the task
        task.setTaskCompleted(success: true)
    }
}




