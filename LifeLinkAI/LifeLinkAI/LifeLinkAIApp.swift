//
//  WatchFirebaseApp.swift
//  WatchFirebase
//
//  Created by Min  on 2024/06/13.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}



@main
struct WatchFirebaseApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationView{
                ContentView(authViewModel: authViewModel)
                    .environmentObject(authViewModel)
//                ProfilePhotoSelectorView()
            }
        }
    }
}
