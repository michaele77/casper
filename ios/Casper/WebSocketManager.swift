import Foundation
import SwiftUI
import Combine
import SocketIO

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    var socket: SocketIOClient!
    var isConnected = false
    let manager = SocketManager(socketURL: URL(string: "ws://" + AppConfig.kServerAddress)!, config: [.log(true), .compress])
    
    // Initialize the socket connection
    init() {
        print("))))) 1")
        
        
        socket = manager.defaultSocket
        
        print("))))) 2")
        
        // Handle the 'connect' event
        socket.on(clientEvent: .connect) { data, ack in
            print("))))) Connected to the server")
            self.isConnected = true // Mark as connected
        }
        print("))))) 3")
        
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
        print("))))) 4 calling connect!")
        socket.connect()
    }
    
    // Disconnect from the server
    func disconnect() {
        print("))))) 5 calling DISCONECt!")
        socket.disconnect()
    }
    
    // Send a message to the server
    func sendMessage(message: String) {
        socket.emit("message", message)
    }
    
    // Send an image to the server
    func sendImage(imageData: Data) {
        if isConnected {
            print("UPLOADDINNGGG <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
            socket.emit("upload_image", imageData)
        } else {
            print("Socket is not connected yet.")
        }
    }
}




//
//class WebSocketManager: ObservableObject {
//    static let shared = WebSocketManager()
//    @Published var echoedImage: UIImage? = nil
//    private var webSocketTask: URLSessionWebSocketTask?
//    
//    // WebSocket URL (adjust to your server's IP/port)
//    private let webSocketURL = URL(string: "ws://" + AppConfig.kServerAddress)!
//    
//    init() {
//        print("-------> WEBSOCKET init")
//        connectWebSocket()
//    }
//    
//    func connectWebSocket() {
//        print("-------> WEBSOCKET connect...")
//        
//        // Initialize custom delegate for SSL certificate handling
//        let delegate = CustomURLSessionDelegate()
//        
//        // Create a URLSession with the custom delegate
//        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
//                    
//        
//        webSocketTask = session.webSocketTask(with: webSocketURL)
//        webSocketTask?.resume()
//        
//        receiveMessages()
//    }
//    
//    func sendImage(imageData: Data) {
//        print("-------> WEBSOCKET SEND IMAGE!!!")
//        let message = URLSessionWebSocketTask.Message.data(imageData)
//        webSocketTask?.send(message) { error in
//            if let error = error {
//                print("Failed to send image: \(error)")
//            }
//        }
//    }
//    
//    private func receiveMessages() {
//        print("-------> WEBSOCKET recieve")
//        webSocketTask?.receive { [weak self] result in
//            switch result {
//            case .failure(let error):
//                print("Error receiving message: \(error)")
//                print("waiting a bit...")
//                Thread.sleep(forTimeInterval: 1.0)
//            case .success(let message):
//                switch message {
//                case .data(let data):
//                    if let image = UIImage(data: data) {
//                        DispatchQueue.main.async {
//                            self?.echoedImage = image
//                        }
//                    }
//                default:
//                    break
//                }
//            }
//            // Keep receiving after processing current message
//            self?.receiveMessages()
//        }
//    }
//    
//    func close() {
//        webSocketTask?.cancel(with: .normalClosure, reason: nil)
//    }
//}
//
//
//class CustomURLSessionDelegate: NSObject, URLSessionDelegate {
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
//            print("))))))) CERTIFICATE 1")
//            // Handle server trust authentication
//            if let serverTrust = challenge.protectionSpace.serverTrust {
//                print("))))))) CERTIFICATE 2")
//                // Load the self-signed certificate from the app's bundle
//                if let certPath = Bundle.main.path(forResource: "certificate", ofType: "crt"),
//                   let certData = try? Data(contentsOf: URL(fileURLWithPath: certPath)) {
//                    print("))))))) CERTIFICATE 3")
//                    // Create a SecCertificate from the certificate data
//                    if let cert = SecCertificateCreateWithData(nil, certData as CFData) {
//                        print("))))))) CERTIFICATE 4")
//                        let certArray = [cert] as CFArray
//                        
//                        // Check if the server's certificate is the same as the one we loaded
//                        let policy = SecPolicyCreateBasicX509()
//                        var trust: SecTrust?
//                        SecTrustCreateWithCertificates(certArray, policy, &trust)
//                        
//                        // Validate trust
//                        if let trust = trust {
//                            print("))))))) CERTIFICATE 5")
//                            var result: SecTrustResultType = .unspecified
//                            SecTrustEvaluate(trust, &result)
//                            
//                            // Check if the certificate is trusted
//                            if result == .proceed || result == .unspecified {
//                                print("))))))) CERTIFICATE 6")
//                                // If the certificate is trusted, proceed
//                                let credential = URLCredential(trust: serverTrust)
//                                completionHandler(.useCredential, credential)
//                                return
//                            }
//                        }
//                    }
//                }
//                // If we didn't find or couldn't validate the certificate, cancel the connection
//                completionHandler(.cancelAuthenticationChallenge, nil)
//            }
//        } else {
//            // For other authentication methods, handle the default case
//            completionHandler(.performDefaultHandling, nil)
//        }
//    }
//}
//
//
////// Custom URLSessionDelegate to handle SSL certificate validation
////class CustomURLSessionDelegate: NSObject, URLSessionDelegate {
////    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
////        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
////            if let serverTrust = challenge.protectionSpace.serverTrust {
////                // Load the self-signed certificate from the app's bundle
////                print("))))))) CERTIFICATE 1")
////                if let certPath = Bundle.main.path(forResource: "certificate", ofType: "crt"),
////                   let certData = try? Data(contentsOf: URL(fileURLWithPath: certPath)) {
////                    print("))))))) CERTIFICATE 2")
////                    let cert = SecCertificateCreateWithData(nil, certData as CFData)
////                    let certArray = [cert] as CFArray
////                    // Create a credential with the server trust
////                    let credential = URLCredential(trust: serverTrust)
////                    completionHandler(.useCredential, credential)
////                }
////            }
////        } else {
////            print("))))))) CERTIFICATE 3")
////            completionHandler(.performDefaultHandling, nil)
////        }
////    }
////}
