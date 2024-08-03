//
//  MessageManager.swift
//  WatchFirebase Watch App
//
//  Created by Min  on 2022/12/16.
//

import FirebaseDatabase
import Foundation
import SwiftUI

class MessageReader: ObservableObject {
    @Published var message = ""
    @ObservedObject var connector = WatchConnector.shared
    var messageRef: DatabaseReference
    var answerRef: DatabaseReference

    var messageHandle: DatabaseHandle?
    var answerHandle: DatabaseHandle?

    init(authViewModel: AuthViewModel) {
        self.messageRef = Database.database().reference().child("\(authViewModel.getUid())/model_message")
        self.answerRef = Database.database().reference().child("\(authViewModel.getUid())/model_answer")
        startMessageListener()
    }
    
    deinit {
        stopMessageListener()
    }
    

    func startMessageListener() {
        messageHandle = messageRef.observe(.value, with: { snapshot in
            if let value = snapshot.value as? String {
                self.message = value
                print(value)
                self.connector.sendTextToWatch(value)
                
            }
        })
        answerHandle = answerRef.observe(.value, with: { snapshot in
            if let value = snapshot.value as? String {
                self.message = value
                self.connector.sendAnswerToWatch(value)
                
            }
        })
    }
    
    func stopMessageListener() {
        if messageHandle != nil {
            messageRef.removeObserver(withHandle: messageHandle!)
        }
        if answerHandle != nil {
            answerRef.removeObserver(withHandle: answerHandle!)
        }
    }
}

class MessageManager: ObservableObject {
//    @EnvironmentObject var viewModel: AuthViewModel
    private var authViewModel: AuthViewModel // Store the AuthViewModel instance
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func sendResponse(_ response: String){
        let timestamp = Date().timeIntervalSince1970
        let data: [String: Any] = ["text": response, "timestamp": timestamp]
        Database.database().reference().child("\(self.authViewModel.getUid())/response").setValue(data)
    }

    func sendQuestion(_ question: String){
        let timestamp = Date().timeIntervalSince1970
        let data: [String: Any] = ["text": question, "timestamp": timestamp]
        Database.database().reference().child("\(self.authViewModel.getUid())/question").setValue(data)
    }
    
}
