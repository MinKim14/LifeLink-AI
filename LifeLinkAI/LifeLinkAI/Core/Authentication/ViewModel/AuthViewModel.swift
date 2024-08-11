//
//  AuthViewModel.swift
//  WatchFirebase
//
//  Created by Min  on 2022/12/15.
//

import SwiftUI
import Firebase

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var didAuthenticateUser = false
    private var tempUserSession: FirebaseAuth.User?
    
    
    init() {
        do {
          try /*Auth.auth().useUserAccessGroup("m-kim-kaist.ac.kr.WatchFirebase4")*/
            Auth.auth().useUserAccessGroup("group.LifelinkAI")
        } catch let error as NSError {
          print("Error changing user access group: %@", error)
        }
        self.userSession = Auth.auth().currentUser
    }
    
    func login(withEmail email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("DEBUG: Failed to sign in with error \(error.localizedDescription)")
                return
            }
            guard let user = result?.user else { return }
            self.userSession = user
            
            print("DEBUG: Did log user in..")
        }

    }
    
    func register(withEmail email: String, password: String, fullname: String, username: String){
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("DEBUG: Failed to register with error \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user else { return }
//            self.userSession = user
            self.tempUserSession = user
            print("DEBUG: Registered user successfully")
            
            let data = ["email": email,
                        "username": username.lowercased(),
                        "fullname":fullname,
                        "uid": user.uid]
            
            Firestore.firestore().collection("users")
                .document(user.uid)
                .setData(data) { _ in
                    print("DEBUG: Did upload user data..")
                    self.didAuthenticateUser = true
                    
                }
        }

    }
    
    
    func signOut() {
        userSession = nil
        try? Auth.auth().signOut()
    }
    func getUid() -> String{
        let userID = Auth.auth().currentUser?.uid ?? "unknown_user"
        return userID
    }
    
}
