import SwiftUI

struct HabitView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var date = Date()
    @State private var habitTitle: String = ""
    @State private var showAddHabitView: Bool = false
    @State private var selectedFrequency: Set<Int> = []
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Date Picker Section
                VStack {
                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                // Habits Section
                if viewModel.habits(for: date).isEmpty {
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
                } else {
                    List {
                        Section(header: Text("Habits for \(date, formatter: Utilities.dateFormatter)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 8)) {
                            ForEach(viewModel.habits(for: date)) { habit in
                                HabitRowView(habit: habit, date: date) {
                                    Task {
                                        try? await viewModel.completeHabit(habit, date)
                                    }
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .transition(.opacity)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .listStyle(InsetGroupedListStyle())
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        Task {
                            do {
                                try await viewModel.fetchHabits()
                            } catch {
                                errorMessage = error.localizedDescription
                                showErrorAlert = true
                            }
                        }
                    }
                }
            }
            
            // Add Habit Button
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
        }
        .sheet(isPresented: $showAddHabitView) {
            AddHabitView(
                habitTitle: $habitTitle,
                selectedFrequency: $selectedFrequency,
                showAddHabitView: $showAddHabitView,
                onSave: {
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
            )
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.loadCurrentUser()
                } catch {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
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
    }
}

// MARK: - HabitRowView
struct HabitRowView: View {
    let habit: Habit
    let date: Date
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: habit.completedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(habit.completedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) ? .green : .blue)
            }
            .padding(.horizontal)
            .buttonStyle(BorderlessButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let description = habit.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
#Preview {
    HabitView()
}
