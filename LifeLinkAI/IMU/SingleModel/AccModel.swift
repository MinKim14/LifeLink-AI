//
//  AccModel.swift
//  WatchFirebase
//
//  Created by Min  on 2022/12/19.
//

import Foundation
import SwiftUI

struct AccModel: Codable {
    
    var Accs = [SingleAcc] ()

    struct SingleAcc: Hashable, Codable {
        var acc_X: Double = 0
        var acc_Y: Double = 0
        var acc_Z: Double = 0
        let time: Double
        
        fileprivate init(acc_X: Double, acc_Y: Double, acc_Z: Double, time: Double) {
            self.acc_X = acc_X
            self.acc_Y = acc_Y
            self.acc_Z = acc_Z
            self.time = time
        }
    }
    
    func acc_x() -> [Double] {

        var x: [Double]  = [Double](repeating: 0.0, count: 100)
        for acc in Accs {
            x.append(acc.acc_X)
        }
        return x.suffix(100)
    }
    func acc_y() -> [Double] {

        var y: [Double]  = [Double](repeating: 0.0, count: 100)
        for acc in Accs {
            y.append(acc.acc_Y)
        }
        return y.suffix(100)
    }
    func acc_z() -> [Double] {

        var z: [Double]  = [Double](repeating: 0.0, count: 100)
        for acc in Accs {
            z.append(acc.acc_Z)
        }
        return z.suffix(100)
    }
    
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
        
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(AccModel.self, from: json)
        
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try AccModel(json: data)
    }
    
    init() { }
    
    mutating func addAcc(x: Double, y: Double, z: Double, time: Double) {
        Accs.append(SingleAcc(acc_X: x, acc_Y: y, acc_Z: z, time: time))
    }
    
    mutating func reset() {
        Accs = []
    }
    

    
    
}
