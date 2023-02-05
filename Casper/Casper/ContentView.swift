//
//  ContentView.swift
//  Casper
//
//  Created by Michael Ershov on 1/8/23.
//

import SwiftUI
import CoreData

struct UserInfo {
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var password: String
}

struct ContentView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    @FocusState private var firstNameIsFocused: Bool
    @FocusState private var lastNameIsFocused: Bool
    @FocusState private var emailIsFocused: Bool
    @FocusState private var phoneNumberIsFocused: Bool
    @FocusState private var passwordIsFocused: Bool
    @FocusState private var confirmPasswordIsFocused: Bool
    
    @State private var signIn: Bool = false
    
    @State var userData = UserInfo(
        firstName: "gFirst",
        lastName: "gLast",
        email: "gEmail",
        phoneNumber: "gNumber",
        password: "gPass")
    
    var body: some View {
        
        NavigationView {
            ZStack {
                Color(.systemGray2)
                    .ignoresSafeArea()
                
                VStack() {
                    Text("CASPER")
                        .font(.custom("Copperplate", size: 80))
                        .foregroundColor(Color(.systemBlue))
                        .offset(x: 0, y: -70)
                    
                    Text("create an account")
                        .font(.custom("Copperplate", size: 30))
                        .bold(false)
                        .foregroundColor(Color(.systemBlue))
                        .offset(x: 0, y: -60)
                    
                    Group {
                        TextField("first Name",
                                  text: $firstName)
                        .focused($firstNameIsFocused)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        
                        TextField("last Name",
                                  text: $lastName)
                        .focused($lastNameIsFocused)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        
                        TextField("email",
                                  text: $email)
                        .focused($emailIsFocused)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        
                        TextField("phone #",
                                  text: $phoneNumber)
                        .focused($phoneNumberIsFocused)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        
                        TextField("password",
                                  text: $password)
                        .focused($passwordIsFocused)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        
                        TextField("confirm password",
                                  text: $confirmPassword)
                        .focused($confirmPasswordIsFocused)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    }.offset(x:0, y:-30)
                    
                    
                    // TODO(mershov): We need validation here (password confirmation, all fields are required, etc).
                    // Once navigating off of the sign up page, dissallow the use of a back button, and persist the input data in a local DB.
                    NavigationLink(
                        destination: MainTabsView()) {
                        Text("sign up")
                            .font(.custom("Copperplate", size: 40))
                            .padding(.horizontal)
                            .foregroundColor(.white)
                            .background(Color(
                            UIColor.systemBlue))
                            .cornerRadius(20)
                            .frame(maxWidth: .infinity)

                        }.simultaneousGesture(TapGesture().onEnded{
                            userData.firstName = firstName
                            userData.lastName = lastName
                            userData.email = email
                            userData.phoneNumber = phoneNumber
                            userData.password = password
                            print("my datamanager list is long")
                            print("firstName is \(firstName)")
                            print("password is \(password)")
                        })
                        
                }
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
