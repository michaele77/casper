//
//  SessionCreationView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//
import SwiftUI

struct SessionCreationView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager
    @State var loadedUUIDs: [String] = []
    @State private var selectedUUID: String = "" // To hold the selected value
    @State var sessionDuration: Int = -1
    
    var body: some View {
        ZStack {
            Color(red: 0.6, green: 0.2, blue: 0.8, opacity: 0.8).ignoresSafeArea() // Lighter purplish red background
            
            VStack() {
                Text("let's start sharing!")
                    .font(.system(size: 30))
                
                if !loadedUUIDs.isEmpty {
                    Picker("Select UUID", selection: $selectedUUID) {
                        Text("who to share with?").tag(nil as String?) // Default, unselected state
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
                
                if !selectedUUID.isEmpty { // Only show these after selecting a UUID
                    // Session Duration Picker
                    Picker("Session Duration", selection: $sessionDuration) {
                        ForEach(1...24, id: \.self) { duration in
                            Text("\(duration) hours").tag(duration) // Display duration in minutes
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // Dropdown style for the duration picker
                    .padding() // Add padding inside the border
                    .background(Color.white) // Set background color of the Picker
                    .cornerRadius(10) // Rounded corners
                    .overlay(
                        RoundedRectangle(cornerRadius: 10) // Border with rounded corners
                            .stroke(Color.purple, lineWidth: 2) // Border color and width
                    )
                    .shadow(radius: 5) // Optional: Add shadow for visual effect
                    .padding(.top) // Add top padding between the pickers

                    // Create Button
                    Button(action: {
                        // Action to create the session
                        print("Creating session with UUID: \(selectedUUID) and Duration: \(sessionDuration) hours")
                        webSocketManager.createSession(sharee: selectedUUID, durationHours: sessionDuration)
                    }) {
                        Text("create session!")
                            .font(.headline)
                            .foregroundColor(Color.white) // Text color for the button
                            .padding()
                            .frame(maxWidth: .infinity) // Make the button span the width
                            .background(Color.purple) // Purple button background
                            .cornerRadius(10) // Rounded corners for the button
                            .shadow(radius: 5) // Optional: Add shadow for the button
                    }
                    .padding([.leading, .trailing, .top], 50) // Add border spacing on sides
                    
                }
                
                
                Spacer()

            } // VStack
        } // ZStack
        .onAppear {
            // Fetch all UUIDs
            webSocketManager.requestAllUUIDs(completion: {uuids in
                loadedUUIDs = uuids ?? []
            })
            
        }
    }
}
struct SessionCreationView_Previews: PreviewProvider {
    static var previews: some View {
        SessionCreationView()
    }
}
