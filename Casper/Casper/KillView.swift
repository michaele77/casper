//
//  KillView.swift
//  Casper
//
//  Created by Michael Ershov on 2/2/24.
//

import SwiftUI

struct KillView: View {
    var body: some View {
        Text("Bye bye!")
                    .onAppear {
                        // Use the exit function to terminate the app
                        exit(-1)
                    }
    }
}

