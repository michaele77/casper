import Foundation
import SwiftUI
import Combine
import SocketIO

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    var socket: SocketIOClient!
    var isConnected = false

    let manager = SocketManager(socketURL: URL(string: "ws://" + AppConfig.kServerAddress)!, config: [.log(true), .compress, .forceWebsockets(true)])
//    let manager = SocketManager(socketURL: URL(string: "wss://" + AppConfig.kServerAddress)!, config: [.log(true), .compress, .forceWebsockets(true), .secure(true), .selfSigned(true)])
    
    // Initialize the socket connection
    init() {
        socket = manager.defaultSocket

        // Handle the 'connect' event
        socket.on(clientEvent: .connect) { data, ack in
            print("))))) Connected to the server")
            self.isConnected = true // Mark as connected
        }

        // Handle the 'message' event (same as Flask event)
        socket.on("message") { data, ack in
            if let message = data[0] as? String {
                print("Received message: \(message)")
            }
        }
        
        // Handle custom events like 'custom_event'
        socket.on("custom_event") { data, ack in
            if let customData = data[0] as? [String: Any] {
                print("Received custom event data: \(customData)")
            }
        }
        
        // Connect to the server
        socket.connect()
        
        // Send the UUID over another custom route.
        // We are garaunteed to create this object and connect at least once during the lifetime of this app; so as long as the server is not shut down during this time, it should have our UUID info.
        // TODO: Note, the identifierForVendor, while unique, does not persist across installations. Meaning, it might drift...IDeally, would generate our own during accouunt creation and store it in user defaults.
        // Note, we have to do a socket.on() event so that we dont sent this BEFORE the connect handshaking goes through.
        socket.on(clientEvent: .connect) { data, ack in
            let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? "ERROR_NO_ID"
            print("Connecting with device UUID: \(deviceUUID)")
            self.socket.emit("register_device", deviceUUID)
        }
    }
    
    // Disconnect from the server
    func disconnect() {
        socket.disconnect()
    }
    
    // Send our UUID to the server.
    func registerDevice(uuid: String) {
        if !isConnected {
            print("Attempted registerDevice before isConnected.")
            return
        }
        socket.emit("register_device", uuid)
    }
    
    // Send a message to the server
    func sendMessage(message: String) {
        if !isConnected {
            print("Attempted sendMessage before isConnected.")
            return
        }
        socket.emit("message", message)
    }
    
    // Send an image to the server
    func sendImage(imageData: Data) {
        if !isConnected {
            print("Attempted sendImage before isConnected.")
            return
        }
        print("UPLOADDINNGGG <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        socket.emit("upload_image", imageData)
    }
    
    func requestAllUUIDs(completion: @escaping ([String]?) -> Void) {
        print("Requesting all UUIDs from server...")
        
        if !isConnected {
            print("Attempted requestAllUUIDs before isConnected.")
            return
        }
        // Remove any existing listener to avoid duplicates
        socket.off("response_all_uuids")
        
        // Add a listener for the response
        // The server sends us a list of string UUIDs that have connected to it.
        socket.on("response_all_uuids") { data, ack in
            if let uuidList = data[0] as? [String] {
                print("Received UUIDs: \(uuidList)")
                completion(uuidList) // Pass the result to the completion handler
            } else {
                print("Failed to parse UUIDs from server.")
                completion(nil) // Indicate an error
            }
        }
        
        // Emit the request
        socket.emit("request_all_uuids")
    }
    
    func requestActiveSessions(completion: @escaping ([(String, Int64)]?) -> Void) {
        print("Requesting all active sessions from server...")
        
        if !isConnected {
            print("Attempted requestActiveSessions before isConnected.")
            return
        }
        // Remove any existing listener to avoid duplicates
        socket.off("response_active_sessions")
        
        // Add a listener for the response
        // The server sends us a tuple of (alias, expiration time) for when the current session expires.
        // Server always responds in UNIX micros for time.
        socket.on("response_active_sessions") { data, ack in
            print("Got these active sessions: \(data)")
            if let arrayData = data[0] as? [[Any]] {
                let receivedTuples = arrayData.compactMap { item -> (String, Int64)? in
                    // Debug print to inspect the types
                    print("Item: \(item), types: \(type(of: item[0])), \(type(of: item[1]))")
                    
                    // Attempt to cast the first item to a String
                    guard let name = item[0] as? String else {
                        print("Failed to cast name")
                        return nil
                    }
                    
                    // Convert the second item (NSDecimalNumber) to Int64
                    guard let ageDecimal = item[1] as? NSDecimalNumber else {
                        print("Failed to cast age to NSDecimalNumber")
                        return nil
                    }
                    
                    // Safely convert NSDecimalNumber to Int64
                    let age = ageDecimal.int64Value
                    
                    return (name, age)
                }
                print(" >> Received array of sessions: \(receivedTuples)")
                completion(receivedTuples)
            }
        }

        // Request sessions from the server
        socket.emit("request_active_sessions")
    }
    
    func updateAlias(newAlias: String) {
        if !isConnected {
            print("Attempted updateAlias before isConnected.")
            return
        }
        print("Updating new alias through web socket!")
        socket.emit("update_alias", newAlias)
    }
    
    func createSession(sharee: String, durationHours: Int) {
        if !isConnected {
            print("Attempted createSession before isConnected.")
            return
        }
        print("Creating new alias through web socket!")
        socket.emit("create_session", sharee, durationHours)
    }
}
