import SwiftUI

struct HomeView: View {
    
    @Binding var showSignInView: Bool
    @StateObject private var viewModel = TaskViewModel()
    @State private var isUserLoadingTimedOut = false
    
    var body: some View {
        Group {
            if viewModel.user != nil {
                TabView {
                    NavigationView {
                        TaskView(showSignInView: $showSignInView)
                            .navigationTitle("Tasks")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tabItem {
                        Label("Tasks", systemImage: "checkmark.square")
                    }
                    
                    NavigationView {
                        HabitView()
                            .navigationTitle("Habits")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tabItem {
                        Label("Habits", systemImage: "star")
                    }
                    
                    NavigationView {
                        TimerView()
                            .navigationTitle("Timers")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                    
                    NavigationView {
                        CalendarView()
                            .navigationTitle("Calendar")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    
                    NavigationView {
                        ProfileView(showSignInView: $showSignInView)
                            .navigationTitle("Profile")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
            } else {
                VStack {
                    Spacer()
                    Text("User is loading...")
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    startUserLoadingTimeout()
                }
            }
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.loadCurrentUser()
                } catch {
                    print("Failed to load user: \(error)")
                }
            }
        }
    }
    
    // MARK: - Timeout Logic
    private func startUserLoadingTimeout() {
        // Timeout after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if viewModel.user == nil && !isUserLoadingTimedOut {
                isUserLoadingTimedOut = true
                showSignInView = true
            }
        }
    }
}

#Preview {
    HomeView(showSignInView: .constant(false))
}
