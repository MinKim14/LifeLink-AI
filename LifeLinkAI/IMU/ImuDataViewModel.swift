//
//  ImuDataViewModel.swift
//  WatchFirebase
//
//  Created by Min  on 2024/06/19.
//

import Foundation


import CoreMotion

struct ImuDataViewModel{

    
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let motionManager = CMMotionManager()

    
    func startMotionManager() {
        self.motionManager.startDeviceMotionUpdates()
        self.motionManager.startAccelerometerUpdates()
    }
    
    func getMotionResult(completion:@escaping (_ error: Error?, _ motionResult: MotionResult ) -> Void) {
        
        var result = MotionResult()
        
        // Will get the device orientation on 3 axis : X, Y, Z.
        if let motion = self.motionManager.deviceMotion {
            let attitude = motion.attitude
            
            result.pitch_X = attitude.pitch
            result.roll_Y = attitude.roll
            result.yaw_Z = attitude.yaw
            
            completion(nil, result)
        }
    }
    
    func getAcceleraionResult(completion:@escaping (_ error: Error?, _ accResult: AccelerationResult ) -> Void) {
        
        var result = AccelerationResult()
        
        if let accelerometerData = self.motionManager.accelerometerData {

            let acc = accelerometerData.acceleration
            result.acc_X = acc.x
            result.acc_Y = acc.y
            result.acc_Z = acc.z
            
            completion(nil, result)
            
        }
    }
    
    struct MotionResult {
        
        // angle are in degreee
        
        var pitch_X: Double = 0
        var roll_Y: Double = 0
        var yaw_Z: Double = 0
        
    }
    
    struct AccelerationResult {
        
        // angle are in degreee
        
        var acc_X: Double = 0
        var acc_Y: Double = 0
        var acc_Z: Double = 0
        
    }
}
