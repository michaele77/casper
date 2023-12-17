//
//  SessionView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI
import Photos
import BackgroundTasks

struct SessionView: View {
    @State var globalVars: GlobalVars
    
    @State private var showNewSessionCreationPage: Bool = false
    @State private var assetMap: [String: Asset] = [:]
    @State private var shownImage: UIImage = UIImage(systemName: "house")!
    
    // This is assumed to be non-nil by the code (something should always be injected).
    var assetLibraryHelper: AssetLibraryHelper?
    
//    init(assetLibraryHelper: AssetLibraryHelper, ) {
//        self.assetLibraryHelper = assetLibraryHelper
//    }
    
    var body: some View {
        ZStack {
            Color(.systemGray2)
                .ignoresSafeArea()
            
            VStack() {
                Text("Sessions!")
                    .onAppear {
                        print("<<9>>")
                        scheduleBackgroundTask()
                    }
                
                Button(action: {
                    assetMap = assetLibraryHelper!.readFromPhotoLibrary()
                }) {
                    Text("read photo library + print it")
                }
                .foregroundColor(Color.red)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Text("size of assetmap: \(assetMap.count)")
                
                Button(action: {
                    shownImage = assetLibraryHelper!.printSingleAsset(assetMap: assetMap)
                }) {
                    Text("print some image")
                }
                .foregroundColor(Color.green)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Button(action: {
                    shownImage = assetLibraryHelper!.fetchLatestAsset()
                }) {
                    Text("print latest image")
                }
                .foregroundColor(Color.yellow)
                .bold(false)
                .font(.custom("Copperplate", size: 20))
                
                Text("Debug info: ")
                Text("--> number of timer counts: \(globalVars.timerTriggerCounter)")
                Text("--> number of active background counts: \(globalVars.activeBackgroundCounter)")
                Text("--> number of inactive background counts: \(globalVars.inactiveBackgroundCounter)")
                Text("--> number of actual tasks triggered: \(globalVars.tasksCounter)")
                Text("--> number of session view tasks counts: \(globalVars.sessionViewTaskCounter)")
                
                Image(uiImage: shownImage)
                
                Button(action: {
                    self.showNewSessionCreationPage.toggle()
                }) {
                    Text("+")
                }
                .sheet(isPresented: $showNewSessionCreationPage) {
                    // Step 4
                    SessionCreationView()
                }
                .frame(width: 100, height: 100)
                .bold(false)
                .font(.custom("Copperplate", size: 100))
                .foregroundColor(Color.white)
                .background(Color(.systemBlue))
                .clipShape(Circle())
                .offset(x:0, y:250)
            }
        }
    }
    
    func scheduleBackgroundTask() {
        print("<<10>>")
        globalVars.sessionViewTaskCounter += 1
        let request = BGAppRefreshTaskRequest(identifier: "photoTask2")
        // Schedule a request in 10 seconds.
        print("Adding a schedule!")
        request.earliestBeginDate = .now
        print("what is now? \(request.earliestBeginDate)")
        request.earliestBeginDate = .now.addingTimeInterval(5)
        print("what is now + 15?? \(request.earliestBeginDate))")
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("DIDNT WORK!!! Error: \(error.localizedDescription)")
        }
        
//            let taskRequest = BGAppRefreshTaskRequest(identifier: "com.yourapp.backgroundTask")
//            taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15) // 15 minutes from now
//
//            do {
//                try BGTaskScheduler.shared.submit(taskRequest)
//            } catch {
//                print("Unable to submit task request: \(error.localizedDescription)")
//            }
    }
}

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        let assetLibraryHelper = AssetLibraryHelper()
        SessionView(globalVars: GlobalVars(), assetLibraryHelper: assetLibraryHelper)
    }
}
