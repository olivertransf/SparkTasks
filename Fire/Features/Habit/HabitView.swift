import SwiftUI

struct HabitView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var date = Date()
    @State private var habitTitle: String = ""
    @State private var showAddHabitView: Bool = false
    @State private var selectedFrequency: Set<Int> = []
    @State private var errorMessage: String? = nil
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    private func dayOfTheWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing) {
            VStack {
                HStack {
                    Text(dayOfTheWeek(for: date))
                        .font(.headline)
                        .foregroundColor(.primary)
        
                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(.vertical)
                    .background(
                        Color(UIColor { traitCollection in
                            traitCollection.userInterfaceStyle == .dark ? .black : .white })
                            .cornerRadius(10)
                    )
                }
                
                if viewModel.habits(for: date).isEmpty {
                    Text("No habits for today!")
                        .font(.title)
                        .foregroundColor(.gray)
                        .padding(.top, 90.0)
                    Text(date, formatter: dateFormatter)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    List {
                        Section("Habits for \(date, formatter: dateFormatter)") {
                            ForEach(viewModel.habits(for: date)) { habit in
                                HStack() {
                                    Button(action: {
                                        Task {
                                            try? await viewModel.completeHabit(habit, date)
                                        }
                                    }) {
                                        Image(systemName: habit.completedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) ? "checkmark.circle" : "circle")
                                            .padding(.horizontal)
                                            .padding(.vertical, 5)
                                            .font(.system(size: 25))
                                    }
                                    .buttonStyle(BorderlessButtonStyle())

                                    VStack(alignment: .leading) {
                                        Text(habit.title)
                                            .font(.headline)
                                            .fontWeight(.medium)
                                        if let description = habit.description {
                                            Text(description)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        Task {
                            do {
                                try await viewModel.fetchHabits()
                            } catch {
                                print("Error refreshing data: \(error.localizedDescription)")
                            }
                        }
                    }

                }
            }
            
            Button(action: { showAddHabitView = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .shadow(radius: 5)
            }
            .padding()
            
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
                }
            }
        }
        .navigationTitle("Habits")
    }
}

struct AddHabitView: View {
    @Binding var habitTitle: String
    @Binding var selectedFrequency: Set<Int>
    @Binding var showAddHabitView: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add a New Habit")
                .font(.largeTitle)
                .bold()
                .padding(.top)
                .foregroundColor(.blue)
            
            TextField("Enter your habit...", text: $habitTitle)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .submitLabel(.done)
                .shadow(radius: 2)
                .padding(.horizontal)
            
            VStack {
                Text("Select Frequency")
                    .font(.headline)
                    .padding(.bottom)
                
                HStack(spacing: 10) {
                    ForEach(0..<7, id: \.self) { index in
                        let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
                        Button(action: {
                            if selectedFrequency.contains(index) {
                                selectedFrequency.remove(index)
                            } else {
                                selectedFrequency.insert(index)
                            }
                        }) {
                            Text(daysOfWeek[index])
                                .foregroundColor(selectedFrequency.contains(index) ? .white : .blue)
                                .frame(width: 40, height: 40)
                                .background(selectedFrequency.contains(index) ? Color.blue : Color.clear)
                                .cornerRadius(20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    habitTitle = ""
                    selectedFrequency = []
                    showAddHabitView = false
                }
                .foregroundColor(.red)
                .font(.headline)
                .padding()
                
                Spacer()
                
                Button(action: onSave) {
                    Text("Add Habit")
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                }
            }
            .padding()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

#Preview {
    RootView()
}
