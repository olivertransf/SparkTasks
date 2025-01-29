import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct AuthenticationView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Title
            VStack(spacing: 8) {
                Text("Welcome Back!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Sign in with one of the following methods.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Authentication Buttons
            VStack(spacing: 15) {
                NavigationLink {
                    SignInEmailView(showSignInView: $showSignInView)
                } label: {
                    authenticationButtonLabel(title: "Sign In With Email", color: Color(red: 66/255, green: 133/255, blue: 244/255), textColor: .white)
                }
                
                Button(action: {
                    Task {
                        do {
                            try await viewModel.signInGoogle()
                            showSignInView = false
                        } catch {
                            print(error)
                        }
                    }
                }) {
                    HStack {
                        Image("Google PNG Image")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)

                        Text("Sign In With Google")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray2))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    Task {
                        do {
                            try await viewModel.signInApple()
                            showSignInView = false
                        } catch {
                            print(error)
                        }
                    }
                }) {
                    SignInWithAppleButtonViewRepresentable(
                        type: .default,
                        style: colorScheme == .dark ? .white : .black
                    )
                    .id(colorScheme)
                    .frame(height: 50)
                    .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // Helper function for creating button labels
    private func authenticationButtonLabel(title: String, color: Color, textColor: Color, image: String? = nil) -> some View {
        HStack {
            if let image = image {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            Text(title)
                .font(.headline)
                .foregroundColor(textColor)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(10)
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AuthenticationView(showSignInView: .constant(false))
        }
    }
}
