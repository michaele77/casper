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
        socket.off("all_uuids")
        
        // Add a listener for the response
        // The server sends us a list of string UUIDs that have connected to it.
        socket.on("all_uuids") { data, ack in
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
}
