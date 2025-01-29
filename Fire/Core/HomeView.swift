import SwiftUI

struct HomeView: View {
    
    @Binding var showSignInView: Bool
    @StateObject private var viewModel = TaskViewModel()

    var body: some View {
        Group {
            if let user = viewModel.user {
                // Main TabView
                TabView {
                    NavigationView {
                        TaskView(showSignInView: $showSignInView)
//                            .navigationTitle("Tasks")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Label("Tasks", systemImage: "checkmark.square")
                    }
                    
                    NavigationView {
                        HabitView()
//                            .navigationTitle("Habits")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Label("Habits", systemImage: "star")
                    }
                    
                    NavigationView {
                        TimerView()
//                            .navigationTitle("Timer")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                    
                    NavigationView {
                        CalendarView()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    
                    NavigationView {
                        ProfileView(showSignInview: $showSignInView)
//                            .navigationTitle("Profile")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                }
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
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    RootView()
}
