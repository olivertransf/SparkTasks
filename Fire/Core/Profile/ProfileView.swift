
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
                    Section("Settings") {
                        Button("Log out") {
                            Task {
                                do {
                                    try viewModel.signOut()
                                    showSignInview = true
                                } catch {
                                    print("Log out failed: \(error)")
                                }
                            }
                        }
                        
                        if viewModel.authProviders.contains(.email) {
                            Button("Reset Password") {
                                Task {
                                    do {
                                        try await viewModel.resetPassword()
                                        print("Password reset sent successfully")
                                    } catch {
                                        print("Password reset failed: \(error)")
                                    }
                                }
                            }
                            
                        }

                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await viewModel.deleteAccount()
                                    showSignInview = true
                                } catch {
                                    print("Account deletion failed: \(error)")
                                }
                            }
                        } label: {
                            Text("Delete account")
                        }
                    }
                }
            }
            .task {
                do {
                    try await viewModel.loadCurrentUser()
                    viewModel.loadAuthProviders()
                } catch {
                    print("Failed to load user: \(error)")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


