//
//  RootView.swift
//  Fire
//
//  Created by Oliver Tran on 1/7/25.
//

import SwiftUI

struct RootView: View {
    
    @State private var showSignInview: Bool = false
    
    var body: some View {
            ZStack {
                if !showSignInview {
                    NavigationStack {
                        
                        TaskView(showSignInView: $showSignInview)

                    }
                }
            }
            .onAppear {
                let authuser = try? AuthenticationManager.shared.getAuthenticatedUser()
                self.showSignInview = authuser == nil
            }
        
            .fullScreenCover(isPresented: $showSignInview) {
                NavigationView {
                    AuthenticationView(showSignInView: $showSignInview)
    }
        }
    }
}

#Preview {
    RootView()
}
