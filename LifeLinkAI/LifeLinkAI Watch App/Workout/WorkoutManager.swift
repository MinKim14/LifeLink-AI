//
//  WorkoutManager.swift
//  WatchFirebase Watch App
//
//  Created by Min  on 2024/06/26.
//

import Foundation
import HealthKit

class WorkoutMananger: NSObject, ObservableObject {
    
    var selectedWorkout: HKWorkoutActivityType?
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    @Published var workoutRunning: Bool = false
    
    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .outdoor
        // Create the session and obtain the workout builder.
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            //            builder = session?.associatedWorkoutBuilder()
            session?.startActivity(with: Date())
            print("DEBUG: Workout session started")
            workoutRunning = true
        } catch {
            // Handle any exceptions.
            print("DEBUG: error in creating workout session")
            return
        }
        
    }
    func stopWorkout() {
        session?.stopActivity(with: Date())
        workoutRunning = false
    }
    
    func toggleWorkout() {
        if(workoutRunning) {
            stopWorkout()
        } else {
            startWorkout()
        }
        
    }
}
