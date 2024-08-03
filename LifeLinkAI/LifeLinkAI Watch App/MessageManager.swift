//
//  MessageManager.swift
//  WatchFirebase Watch App
//
//  Created by 고승훈 on 6/19/24.
//

import Foundation
import FirebaseDatabase

class MessageManager: ObservableObject {
    @Published var message = "Does it work?"
    lazy var messageRef: DatabaseReference = Database.database().reference().ref.child("/messsage")
    var messageHandle: DatabaseHandle?
    
    func startMessageListener(){
        messageHandle = messageRef.observe(.value, with : { snapshot in
            if let value = snapshot.value as? String {
                self.message = value
            }
            
        })
    }
}
