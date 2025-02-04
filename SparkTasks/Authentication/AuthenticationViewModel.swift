//
//  AuthenticationViewModel.swift
//
//  Created by Oliver Tran on 1/9/25.
//

import Foundation
import CryptoKit
import AuthenticationServices

@MainActor
final class AuthenticationViewModel: ObservableObject{
    
    let signInAppleHelper = SignInAppleHelper()
    
    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        let authDataResult = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        
        let uid = authDataResult.uid
        
        // Check if user already exists
        let userExists = try await UserManager.shared.checkUserExists(uid: uid)
        
        if !userExists {
            // Create user document only if it doesn't exist
            let user = DBUser(auth: authDataResult)
            try await UserManager.shared.createNewUser(user: user)
            print("New user document created.")
        } else {
            print("User already exists, skipping document creation.")
        }
    }
    
    func signInApple() async throws {
        
        let helper = SignInAppleHelper()
        let tokens = try await helper.startSignInWithAppleFlow()
        let authDataResult = try await AuthenticationManager.shared.signInWithApple(tokens: tokens)

        let uid = authDataResult.uid
        
        // Check if user already exists
        let userExists = try await UserManager.shared.checkUserExists(uid: uid)
        
        if !userExists {
            // Create user document only if it doesn't exist
            let user = DBUser(auth: authDataResult)
            try await UserManager.shared.createNewUser(user: user)
            print("New user document created.")
        } else {
            print("User already exists, skipping document creation.")
        }
    }
    
}
