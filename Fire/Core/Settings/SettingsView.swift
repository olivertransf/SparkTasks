//
//  SettingsView.swift
//  Fire
//
//  Created by Oliver Tran on 1/7/25.
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        List {
            Button("Log out") {
                Task {
                    do {
                        try viewModel.signOut()
                        showSignInView = true
                    } catch {
                        print(error)
                    }
                }
            }
            
            Button(role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteAccount()
                        showSignInView = true
                    } catch {
                        print(error)
                    }
                }
            } label: {
                Text("Delete account")
            }
            
            if viewModel.authProviders.contains(.email) {
                Section("Email") {
                    Button("Reset Password") {
                        Task {
                            do {
                                try await viewModel.resetPassword()
                                print("Password reset sent successfully")
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadAuthProviders()
        }
        .navigationTitle(Text("Settings"))
    }
}

#Preview {
    NavigationStack {
        SettingsView(showSignInView: .constant(false))
    }
}
