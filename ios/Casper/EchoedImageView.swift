import SwiftUI

struct EchoedImageView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager
    
    var body: some View {
        VStack {
            Text("Echo image view")
//            if let echoedImage = webSocketManager.echoedImage {
//                Image(uiImage: echoedImage)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(height: 300)
//            } else {
//                Text("No echoed image received yet.")
//            }
        }
        .onAppear {
            // You could initiate an action when this view appears, if needed.
        }
    }
}
