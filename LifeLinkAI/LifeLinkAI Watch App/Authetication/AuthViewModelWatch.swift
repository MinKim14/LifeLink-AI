//
//  AuthViewModel.swift
//  WatchFirebase
//
//  Created by Min  on 2022/12/19.
//

import Foundation
import Firebase
import FirebaseAuth

class AuthViewModelWatch: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    
    init() {
        do {
          try Auth.auth().useUserAccessGroup("m-kim-kaist.ac.kr.WatchFirebase")
        } catch let error as NSError {
          print("Error changing user access group: %@", error)
        }
        self.userSession = Auth.auth().currentUser
    }
}
