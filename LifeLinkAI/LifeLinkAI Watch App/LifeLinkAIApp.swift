
import SwiftUI
import Firebase



@main
struct LifeLinkAI_Watch_App: App {
    
    @StateObject var workoutMananger = WorkoutMananger()
    var body: some Scene {
        WindowGroup {
            NavigationView{
                ContentView()
            }
            .environmentObject(workoutMananger)
        }
    }
}
