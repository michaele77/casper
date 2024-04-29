//
//  SessionCreationView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI

struct SessionCreationView: View {
    var body: some View {
        ZStack {
            Color(red: 124/255, green: 205/255, blue: 250/255)
                .ignoresSafeArea()
            
            VStack() {
                Text("We making a new view!")
                    .font(.custom("Copperplate", size: 50))
            }
        }
    }
}

struct SessionCreationView_Previews: PreviewProvider {
    static var previews: some View {
        SessionCreationView()
    }
}
