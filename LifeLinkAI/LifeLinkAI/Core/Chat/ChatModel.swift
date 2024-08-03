//
//  ChatModel.swift
//  WatchFirebase
//
//  Created by Min  on 2024/07/19.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage

import SwiftUI


struct ChatMessage: Identifiable {
    let id: String
    let sender: String
    let text: String
    let timestamp: Date
}
// ViewModel for Firebase interaction
class FirebaseViewModel: ObservableObject {

    @Published var image: UIImage?
    @Published var isLoading = true
    @Published var chatMessages: [ChatMessage] = []

    
    var chatsRef: DatabaseReference
    var summaryRef: DatabaseReference
    var dateOverviewRef: DatabaseReference
    
    private var messageHandle: DatabaseHandle?
    private var overviewHandle: DatabaseHandle?
    
    private var authViewModel: AuthViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self.chatsRef = Database.database().reference().child("\(authViewModel.getUid())/chats")
        self.summaryRef = Database.database().reference().child("\(authViewModel.getUid())/summaries")
        self.dateOverviewRef = Database.database().reference().child("\(authViewModel.getUid())/overview")
        fetchDaySummaries(Date())
        startMessageListener()
    }
    
    deinit {
        stopMessageListener()
    }
    @Published var daySummary: DaySummary?
    @Published var daySummaries: [DaySummary] = []
    @Published var dateOverview: String = ""
    

    private var db = Firestore.firestore()
    private var chatListener: ListenerRegistration?
    private var summaryListener: ListenerRegistration?
    
    func startMessageListener() {
            messageHandle = chatsRef.observe(.value, with: { [weak self] snapshot in
                guard let self = self else { return }
                self.chatMessages = []
                for dateSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    let snap_date: String = dateSnapshot.key

                    if(snap_date == formatDate(Date())){
                        for messageSnapshot in dateSnapshot.children.allObjects as! [DataSnapshot] {

                            
                            let messageDict = messageSnapshot.value! as! [String : Any]
                            let id = messageDict["id"] as? String
                            let sender = messageDict["sender"] as? String
                            let text = messageDict["text"] as? String
                            let timestampString = messageDict["timestamp"] as? String

                            let chatMessage = ChatMessage(id: id! , sender: sender! , text: text! , timestamp: Date())
                            
                            self.chatMessages.append(chatMessage)
                        }
                    }
                }
            }, withCancel: { error in
                print("Failed to observe value: \(error.localizedDescription)")
            })
        }
        
        func stopMessageListener() {
            if let handle = messageHandle {
                chatsRef.removeObserver(withHandle: handle)
            }
            
        }
    // Custom function to update the UIImageView
    func fetchImage(for date: Date) {
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("\(authViewModel.getUid())/visualize/\(formatDate(date)).jpg")
        self.isLoading = true

        imageRef.getData(maxSize: 10 * 1024 * 1024) { [weak self] data, error in
            DispatchQueue.main.async {
                if let data = data, let loadedImage = UIImage(data: data) {
                    self?.image = loadedImage
                    self?.isLoading = false
                } else {
                    print("Error fetching image: \(String(describing: error))")
                    self?.isLoading = true
                }
            }
        }
    }
    // Fetch all summaries
    func fetchDaySummaries(_ cur_date: Date){
        self.dateOverview = ""
        overviewHandle = dateOverviewRef.observe(.value, with: { [weak self] snapshot in
            guard self != nil else { return }
            for dateSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                let snap_date: String = dateSnapshot.key
                if(snap_date == formatDate(cur_date)){
//                    let dateOverview = dateSnapshot.value!
                    if let value = dateSnapshot.value as? String {
                        self?.dateOverview = value
                    }
                }
            }

        })
        messageHandle = summaryRef.observe(.value, with: { [weak self] snapshot in
            guard self != nil else { return }
            //            var newMessages: [ChatMessage] = []
            self?.daySummaries = []
            for dateSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                
                let snap_date: String = dateSnapshot.key
                if(snap_date == formatDate(cur_date)){
                    for messageSnapshot in dateSnapshot.children.allObjects as! [DataSnapshot] {
                        let messageDict = messageSnapshot.value! as! [String : Any]
                        let id = messageDict["id"] as? String
                        let startTime = messageDict["startTime"] as? String
                        let endTime = messageDict["endTime"] as? String
                        let actionKeyword = messageDict["actionKeyword"] as? String
                        let metaData = messageDict["metaData"] as? String
                        let summary = messageDict["summary"] as? String
                        
                        

                        let cur_summary = DaySummary(id: id! , startTime: startTime! , endTime: endTime! , actionKeyword: actionKeyword! , metaData: metaData! , summary: summary! )
                        
                        self?.daySummaries.append(cur_summary)
                    }
                }

            }
        })
        fetchImage(for: cur_date)
   }
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
