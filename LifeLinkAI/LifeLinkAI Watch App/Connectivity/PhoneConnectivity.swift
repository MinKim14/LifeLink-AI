//
//  WatchConnectivity.swift
//  WatchFirebase Watch App
//
//  Created by Min  on 2024/06/19.
//

import Foundation
import WatchConnectivity
import SwiftUI

class PhoneConnector:NSObject,ObservableObject {
    
    // public variables
    
    static let shared = PhoneConnector()
    @Published var model_response: String = ""
    @Published var model_answer: String = ""

    public let session = WCSession.default
        
        
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
}

// MARK: - WCSessionDelegate methods
extension PhoneConnector:WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        dataReceivedFromPhone(userInfo)
    }
    
    // MARK: use this for testing in simulator
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        dataReceivedFromPhone(message)
    }
    
}


// MARK: - send data to phone
extension PhoneConnector {
    public func sendTextToPhone(_ response:String, completion: @escaping () -> Void){
        let dict: [String: Any] = ["response": response]
        session.sendMessage(dict, replyHandler: nil)
        completion()
    }
    public func sendQuestionToPhone(_ response:String, completion: @escaping () -> Void){
        let dict: [String: Any] = ["question": response]
        session.sendMessage(dict, replyHandler: nil)
        completion()

    }
    public func sendDataToPhone(_ accModel:AccModel, _ gyroModel: GyroModel) {
        let curAccData: Data? = try? accModel.json()
        let curGyroData: Data? = try? gyroModel.json()
        let dict:[String:Any] = ["acc": curAccData!, "gyro": curGyroData!]


        session.sendMessage(dict, replyHandler: nil)
    }
    
}

// MARK: - receive data
extension PhoneConnector {
    
    public func dataReceivedFromPhone(_ info:[String:Any]) {

        let keyExists = info["response"] != nil
        if keyExists{
            let response: String = info["response"] as! String
            DispatchQueue.main.async {
                self.model_response = response
            }
        }
        
        let answerExists = info["answer"] != nil
        if answerExists{
            let response: String = info["answer"] as! String
            DispatchQueue.main.async {
                self.model_answer = response
            }
        }
    }
    
}

    
    

