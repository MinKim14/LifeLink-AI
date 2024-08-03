//
//  WatchConnector.swift
//  WatchFirebase
//
//  Created by Min  on 2024/06/19.
//

import Foundation
import WatchConnectivity
import FirebaseStorage
import SwiftUI

class WatchConnector: NSObject, ObservableObject {
    @Published var accModel: AccModel = AccModel()
    @Published var oriModel: GyroModel = GyroModel()
    @Published var databaseManager: MessageManager
    static let shared = WatchConnector(authViewModel: AuthViewModel()) // Placeholder instance, replace with actual

    public let session = WCSession.default
    private var authViewModel: AuthViewModel // Store the AuthViewModel instance

    private init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self.databaseManager = MessageManager(authViewModel: authViewModel)
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // Other methods...
}
extension WatchConnector:WCSessionDelegate {
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        session.activate()
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
    }
    
    // MARK: use this for testing in simulator
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        dataReceivedFromWatch(message)
    }
    
}

extension WatchConnector {
    public func dataReceivedFromWatch(_ info:[String:Any]) {
        let keyExists = info["response"] != nil
        let questionExists = info["question"] != nil
        if keyExists{
            let response: String = info["response"] as! String
            databaseManager.sendResponse(response)
        }
        else if questionExists{
            let question: String = info["question"] as! String
            databaseManager.sendQuestion(question)
            
        }
        else {
        
            let accData:Data = info["acc"] as! Data
            let oriData:Data = info["gyro"] as! Data
            DispatchQueue.main.async {
                self.accModel = try! AccModel(json: accData)
                self.oriModel = try! GyroModel(json: oriData)
            }
            let curTime: String = String(NSDate().timeIntervalSince1970)
            let filenameGyro = "gyro_" + curTime
            let filenameAcc = "acc_" + curTime
            let refGyro = Storage.storage().reference().child("\(self.authViewModel.getUid())/data/\(filenameGyro)"
            )
            let curGyroData: Data? = try? self.oriModel.json()
            if let curGyroData = curGyroData {
                refGyro.putData(curGyroData)
            }
            let refAcc = Storage.storage().reference().child("\(self.authViewModel.getUid())/data/\(filenameAcc)"
            )

            let curAccData: Data? = try? self.accModel.json()
            if let curAccData = curAccData {
                refAcc.putData(curAccData){
                    (_, err) in
                    if let err = err {
                        print("an error has occurred - \(err.localizedDescription)")
                    } 
                }
            }
        }
       
    }
}

extension WatchConnector {

    public func sendTextToWatch(_ model_response:String) {
//        let curAccData: Data? = try? accModel.json()
//        let curOriData: Data? = try? gyroModel.json()
        let dict:[String:Any] = ["response": model_response]

        session.sendMessage(dict, replyHandler: nil)
    }
    public func sendAnswerToWatch(_ model_response:String) {

        let dict:[String:Any] = ["answer": model_response]
        session.sendMessage(dict, replyHandler: nil)
    }
}
