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
    @State private var selectedUUID: String = "" // To hold the selected value
    @EnvironmentObject var webSocketManager: WebSocketManager
    @State var loadedUUIDs: [String] = []
        
    // DataManagers
    let statsManager = StatsManager()
    let imageManager = ImageDataManager()
    
    var body: some View {
        VStack {
            if !loadedUUIDs.isEmpty {
                Picker("Select UUID", selection: $selectedUUID) {
                    ForEach(loadedUUIDs, id: \.self) { uuid in
                        Text(uuid).tag(uuid) // Set the value of the tag to be the UUID
                    }
                }
                .pickerStyle(MenuPickerStyle()) // Use the MenuPickerStyle for dropdown-like UI
                .padding() // Add padding inside the border
                .background(Color.white) // Set background color of the Picker
                .cornerRadius(10) // Rounded corners
                .overlay(
                    RoundedRectangle(cornerRadius: 10) // Border with rounded corners
                        .stroke(Color.blue, lineWidth: 2) // Border color and width
                )
                .shadow(radius: 5) // Optional: Add shadow for visual effect
                            
            } else {
                Text("Loading UUIDs...")
            }
            
            Text("Sessions!").padding()
            Text("Loaded UUIDs: \(loadedUUIDs.joined(separator: ", "))")
                            .padding()
        }
        .onAppear {
            webSocketManager.sendMessage(message: "Focusing sessions!")
            webSocketManager.requestAllUUIDs(completion: {uuids in
                loadedUUIDs = uuids ?? []
            })
        }
    }
     
}

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
    }
}
