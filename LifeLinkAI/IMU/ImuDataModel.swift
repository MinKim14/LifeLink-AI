//
//  ImuDataModel.swift
//  WatchFirebase
//
//  Created by Min  on 2024/06/19.
//

import Foundation
import CoreMotion
import FirebaseStorage

import Combine
import WatchConnectivity
import SwiftUI
class ImuDataModel: ObservableObject {

    private var motionManager: CMMotionManager = CMMotionManager()
    @ObservedObject var connector = PhoneConnector.shared

    @Published var accModel: AccModel = AccModel()
    @Published var gyroModel: GyroModel = GyroModel()
    

    private struct ImuSave {
        static let fileDir = NSDate().timeIntervalSince1970
        
        static let imuSaveFPS: Double = 60.0
    }
    
    init() { }
//    var session: WCSession
//    let delegate: WCSessionDelegate
    
    let dateFormatter = DateFormatter()
    private var accSaveTime: Timer?
    private var gyroSaveTime: Timer?
    
    @Published var imuRunning: Bool = false
    
    func startMotionMananger() {
        self.motionManager.startDeviceMotionUpdates()
        self.motionManager.startAccelerometerUpdates()
       
        gyroSaveTime = Timer.scheduledTimer(withTimeInterval: 1/ImuSave.imuSaveFPS, repeats: true, block: { Timer in
            if let motion = self.motionManager.deviceMotion {
                let attitude = motion.attitude
                let curTime = NSDate().timeIntervalSince1970
                self.gyroModel.addGyro(pitch: attitude.pitch, roll: attitude.roll, yaw: attitude.yaw, time: curTime)
            } else{
                let curTime = NSDate().timeIntervalSince1970
                self.gyroModel.addGyro(pitch: Double.random(in: 1..<10), roll: Double.random(in: 1..<10), yaw: Double.random(in: 1..<10), time: curTime)
            }
        })
        
        accSaveTime = Timer.scheduledTimer(withTimeInterval: 1/ImuSave.imuSaveFPS, repeats: true, block: { _ in
            if let accelerometerData = self.motionManager.accelerometerData {
                let acc = accelerometerData.acceleration
                let curTime = NSDate().timeIntervalSince1970
                self.accModel.addAcc(x: acc.x, y: acc.y, z: acc.z, time: curTime)
            } else {
                let curTime = NSDate().timeIntervalSince1970
                self.accModel.addAcc(x: Double.random(in: 1..<10), y: Double.random(in: 1..<10), z: Double.random(in: 1..<10), time: curTime)
            }

        })
        imuRunning = true

    }
    func stopMotionMananger() {
        gyroSaveTime?.invalidate()
        accSaveTime?.invalidate()
        imuRunning = false
    }
    func toggleMotion() {
        if(imuRunning) {
            stopMotionMananger()
        } else {
            startMotionMananger()
        }
        
    }
    
    
    func num_data() -> Int {
        return accModel.Accs.count
    }
    
    private var autosaveTimer: Timer?
    @Published var indicator: Bool = false
    @Published var saveRunning: Bool = false
    func toggleSave() {
        if(saveRunning) {
            self.stopAutoSave()
        } else {
            self.scheduleAutoSave()
        }
        
    }
    
    
    func stopAutoSave() {
        autosaveTimer?.invalidate()
        saveRunning = false
    }
    
    func scheduleAutoSave() {
        self.indicator = true
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { _ in
            DispatchQueue.main.async {
                
                self.connector.sendDataToPhone(self.accModel, self.gyroModel)
                self.gyroModel.reset()
                self.accModel.reset()

            }

            self.indicator = false

        })
        saveRunning = true
        
    }
    
    
    
    
}

