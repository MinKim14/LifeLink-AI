//
//  GyroModel.swift
//  WatchFirebase
//
//  Created by Min  on 2022/12/19.
//

import Foundation


struct GyroModel: Codable {
    
    var Gyros = [SingleGyro] ()
    
    struct SingleGyro: Hashable, Codable {
        var pitch_X: Double = 0
        var roll_Y: Double = 0
        var yaw_Z: Double = 0
        let time: Double
        
        fileprivate init(pitch_X: Double, roll_Y: Double, yaw_Z: Double, time: Double) {
            self.pitch_X = pitch_X
            self.roll_Y = roll_Y
            self.yaw_Z = yaw_Z
            self.time = time
//            self.id = NSDate().timeIntervalSince1970
        }
    }
    func pitch_x() -> [Double] {

        var x: [Double]  = [Double](repeating: 0.0, count: 100)
        for gyro in Gyros {
            x.append(gyro.pitch_X)
        }
        return x.suffix(100)
    }
    func roll_y() -> [Double] {

        var y: [Double]  = [Double](repeating: 0.0, count: 100)
        for gyro in Gyros {
            y.append(gyro.roll_Y)
        }
        return y.suffix(100)
    }
    func yaw_z() -> [Double] {

        var z: [Double]  = [Double](repeating: 0.0, count: 100)
        for gyro in Gyros {
            z.append(gyro.yaw_Z)
        }
        return z.suffix(100)
    }
    
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
        
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(GyroModel.self, from: json)
        
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try GyroModel(json: data)
    }
    
    init() { }
    
    mutating func addGyro(pitch: Double, roll: Double, yaw: Double, time: Double) {
        Gyros.append(SingleGyro(pitch_X: pitch, roll_Y: roll, yaw_Z: yaw, time: time))
    }
    
    mutating func reset() {
        Gyros = []
    }
}
