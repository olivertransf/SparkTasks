
//
//  Profile View.swift
//  Fire
//
//  Created by Oliver Tran on 1/27/25.
//
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Binding var showSignInview: Bool

    var body: some View {
        NavigationView {
            List {
                if let user = viewModel.user {
                    Section("Profile Info") {
                        Text("UserID: \(user.userId)")
                        Text("Email: \(user.email ?? "Not Set")")
                        if let dateCreated = user.dateCreated {
                            Text("Date Created: \(dateCreated.formatted(date: .abbreviated, time: .omitted))")
                        }
                    }
                }

                SettingsView(showSignInview: $showSignInview)
            }
            .task {
                do {
                    try await viewModel.loadCurrentUser()
                } catch {
                    print("Failed to load user: \(error)")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


