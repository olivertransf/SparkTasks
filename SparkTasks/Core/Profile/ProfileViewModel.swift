//
//  ProfileView.swift
//  Fire
//
//  Created by Oliver Tran on 1/9/25.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published private(set) var user: DBUser? = nil
    
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
    }
    
    @Published var authProviders: [AuthProviderOption] = []
    
    func loadAuthProviders() {
        if let providers = try? AuthenticationManager.shared.getProviders() {
            authProviders = providers
        }
    }
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
    
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let email = authUser.email else {
            throw URLError(.badURL)
        }
        
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
    func deleteAccount() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        
        let uid = authUser.uid
        
        let db = Firestore.firestore()
        
        // Delete user document from Firestore
        try await db.collection("users").document(uid).delete()
        
        // Delete user from Firebase Authentication
        try await AuthenticationManager.shared.deleteAccount()
    }
}
