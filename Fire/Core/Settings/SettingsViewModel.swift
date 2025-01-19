//
//  Untitled.swift
//  Fire
//
//  Created by Oliver Tran on 1/9/25.
//

import Foundation
import FirebaseFirestore

@MainActor
final class SettingsViewModel: ObservableObject {
    
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
        try await AuthenticationManager.shared.delete()
    }
}
