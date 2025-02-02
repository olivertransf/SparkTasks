//
//  FireApp.swift
//  Fire
//
//  Created by Oliver Tran on 1/6/25.
//

import SwiftUI
import Firebase

@main
struct SparkTasksApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

}

class AppDelegate : NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        print("Configured Firebase")
        
        return true
    }
}
