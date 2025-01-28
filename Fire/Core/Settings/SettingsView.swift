//
//  SettingsView.swift
//  Fire
//
//  Created by Oliver Tran on 1/7/25.
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInview: Bool
    
    var body: some View {
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
        .onAppear {
            viewModel.loadAuthProviders()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(showSignInview: .constant(false))
    }
}
