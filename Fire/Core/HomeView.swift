import SwiftUI
import Network

class NetworkMonitor: ObservableObject {
    
    static let shared = NetworkMonitor()
    
    @Published var isOnline: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}

struct HomeView: View {
    
    @Binding var showSignInView: Bool
    @StateObject private var viewModel = TaskViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
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
                .overlay(networkMonitor.isOnline ? nil : offlineBanner)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if viewModel.user == nil && !isUserLoadingTimedOut {
                isUserLoadingTimedOut = true
                showSignInView = true
            }
        }
    }

    // MARK: - Offline Banner
    private var offlineBanner: some View {
        VStack {
            HStack {
                Text("You're offline")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.bottom, 10)
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
        .animation(.easeInOut, value: networkMonitor.isOnline)
    }
}

#Preview {
    HomeView(showSignInView: .constant(false))
}
