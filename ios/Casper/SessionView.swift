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
    @EnvironmentObject var webSocketManager: WebSocketManager
    // Tuples of sessions: (alias of the sessionee, the expiration of the session).
    @State var activeSessions: [(String, Int64)] = []
    @State private var showNewSessionCreationPage: Bool = false
    // The User Alias will be sent to the server; it will use this to present yourself to others
    @State private var userAlias: String = ""
        
    // DataManagers
    let statsManager = StatsManager()
    let imageManager = ImageDataManager()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Black background
            VStack(spacing: 20) {
                HStack {
                    // Text box
                    TextField("your name (others will see this)", text: $userAlias)
                        .padding()
                        .background(Color(red: 0.6, green: 0.2, blue: 0.8, opacity: 0.2)) // Lighter purplish red background
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    
                    // Button
                    Button(action: {
                        print("Update button pressed with input: \(userAlias)")
                        webSocketManager.updateAlias(newAlias: userAlias)
                    }) {
                        Text("update")
                            .padding()
                            .background(Color(red: 0.7, green: 0.6, blue: 0.7)) // Slightly darker purple
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: Color.purple.opacity(0.6), radius: 5, x: 0, y: 5)
                    }
                } // HStack
                .padding([.leading, .trailing], 20) // Add border spacing on sides
                
                Button(action: {
                    print("Create New Session button pressed")
                    self.showNewSessionCreationPage = true
                }) {
                    Text("create new session")
                        .padding()
                        .frame(maxWidth: .infinity) // Ensure button stretches horizontally to look balanced
                        .background(Color(red: 0.85, green: 0.25, blue: 0.6)) // Another unique purple-red tone
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: Color.purple.opacity(0.4), radius: 5, x: 0, y: 5)
                        .padding([.leading, .trailing], 50) // Add horizontal padding for balance
                }
                .sheet(isPresented: $showNewSessionCreationPage) {
                    SessionCreationView()
                }

                Text("All active sessions: \(activeSessions.map{"- \($0.0): \($0.1) -"}.joined(separator: ", "))")
                                .padding()
                
                Spacer()
                
                
            } // VStack
        } // ZStack
        .onAppear {
            // Fetch all active sessions
            webSocketManager.requestActiveSessions(completion: {sessions in
                activeSessions = sessions ?? []
            })
        }
    }
     
}

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
    }
}
