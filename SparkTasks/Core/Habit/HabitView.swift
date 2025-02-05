import SwiftUI

struct HabitView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var date = Date()
    @State private var habitTitle: String = ""
    @State private var showAddHabitView: Bool = false
    @State private var selectedFrequency: [Int] = []
    @Environment(\.colorScheme) var colorScheme
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    @State var isEditing: Bool = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                calendarView
                habitSection
            }
            addHabitButton
        }
        .sheet(isPresented: $showAddHabitView) {
            addHabitSheet
        }
        .onAppear {
            setupOnAppear()
        }
        .alert(
            "Error",
            isPresented: $showErrorAlert,
            presenting: errorMessage
        ) { message in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
        .environmentObject(viewModel)
    }
    
    private var calendarView: some View {
        FSCalendarView(selectedDate: $date, events: [], colorScheme: colorScheme)
            .frame(height: 350)
            .padding(.horizontal)
            .padding(.top, 10)
    }
    
    private var habitSection: some View {
        Group {
            if viewModel.habits(for: date).isEmpty {
                emptyStateView
            } else {
                habitList
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tortoise.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No habits for today!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            Text(date, formatter: Utilities.dateFormatter)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var habitList: some View {
        List {
            Section(header: listHeader) {
                ForEach(viewModel.habits(for: date)) { habit in
                    habitRow(for: habit)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .refreshable {
            await refreshHabits()
        }
    }
    
    private var listHeader: some View {
        Text("Habits for \(date, formatter: Utilities.dateFormatter)")
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.vertical, 8)
    }
    
    private func habitRow(for habit: Habit) -> some View {
        HabitRowView(
            habit: habit,
            date: date,
            onComplete: {
                Task {
                    try? await viewModel.completeHabit(habit, date)
                }
            },
            onDelete: {
                Task {
                    try await viewModel.deleteHabit(habit)
                }
            },
            online: networkMonitor.isOnline
        )
        .environmentObject(viewModel)
        .transition(.opacity)
    }
    
    private var addHabitButton: some View {
        Button(action: { showAddHabitView = true }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding()
                .background(
                    Circle()
                        .fill(Color.blue)
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .buttonStyle(PlainButtonStyle())
        .disabled(!networkMonitor.isOnline)
    }
    
    private var addHabitSheet: some View {
        AddHabitView(
            habitTitle: $habitTitle,
            selectedFrequency: $selectedFrequency,
            showAddHabitView: $showAddHabitView,
            onSave: saveNewHabit
        )
    }
    
    private func saveNewHabit() {
        let trimmedTitle = habitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        Task {
            do {
                try await viewModel.addHabit(
                    habitName: trimmedTitle,
                    interval: Array(selectedFrequency),
                    description: nil
                )
                showAddHabitView = false
                habitTitle = ""
                selectedFrequency = []
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func setupOnAppear() {
        Task {
            do {
                try await viewModel.loadCurrentUser()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func refreshHabits() async {
        do {
            try await viewModel.fetchHabits()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}


