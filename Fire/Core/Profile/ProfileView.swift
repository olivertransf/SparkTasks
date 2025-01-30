import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Binding var showSignInView: Bool

    var body: some View {
        VStack(spacing: 20) {
            if let user = viewModel.user {
                // MARK: - Profile Header
                VStack(spacing: 12) {
                    if let photoUrl = user.photoUrl, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                    
                    Text(user.email ?? "Not Set")
                        .font(.title2)
                        .bold()
                    
                    if let dateCreated = user.dateCreated {
                        Text("Joined: \(dateCreated.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // MARK: - Settings
                List {
                    Section {
                        Button {
                            Task {
                                do {
                                    try viewModel.signOut()
                                    showSignInView = true
                                } catch {
                                    print("Log out failed: \(error)")
                                }
                            }
                        } label: {
                            Label("Log Out", systemImage: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if viewModel.authProviders.contains(.email) {
                        Section {
                            Button {
                                Task {
                                    do {
                                        try await viewModel.resetPassword()
                                        print("Password reset sent successfully")
                                    } catch {
                                        print("Password reset failed: \(error)")
                                    }
                                }
                            } label: {
                                Label("Reset Password", systemImage: "key.fill")
                            }
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await viewModel.deleteAccount()
                                    showSignInView = true
                                } catch {
                                    print("Account deletion failed: \(error)")
                                }
                            }
                        } label: {
                            Label("Delete Account", systemImage: "trash.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
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
}

// MARK: - Preview
#Preview {
    ProfileView(showSignInView: .constant(false))
}
