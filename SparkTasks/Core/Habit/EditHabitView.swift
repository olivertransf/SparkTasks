import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: HabitViewModel
    
    let habit: Habit
    
    @State private var habitTitle: String
    @State private var selectedFrequency: [Int]
    @State private var habitDescription: String
    
    init(habit: Habit) {
        self.habit = habit
        _habitTitle = State(initialValue: habit.title)
        _selectedFrequency = State(initialValue: habit.interval)
        // If the habit description is nil, default to an empty string.
        _habitDescription = State(initialValue: habit.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Habit Title").font(.headline)) {
                    TextField("Enter habit title", text: $habitTitle)
                        .font(.body)
                }
                
                Section(header: Text("Habit Description").font(.headline)) {
                    TextField("Enter description", text: $habitDescription)
                        .font(.body)
                }
                
                Section(header: Text("Select Frequency").font(.headline)) {
                    HStack(spacing: 10) {
                        let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
                        ForEach(0..<7, id: \.self) { index in
                            Button(action: {
                                toggleDay(index)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(selectedFrequency.contains(index) ? Color.blue : Color.clear)
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                    Text(daysOfWeek[index])
                                        .foregroundColor(selectedFrequency.contains(index) ? .white : Color.blue)
                                }
                                .frame(width: 40, height: 40)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Circle())
                        }
                    }
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveHabitEdits()
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleDay(_ index: Int) {
        withAnimation {
            if let pos = selectedFrequency.firstIndex(of: index) {
                selectedFrequency.remove(at: pos)
            } else {
                selectedFrequency.append(index)
                selectedFrequency.sort()
            }
        }
    }
    
    private func saveHabitEdits() async {
        do {
            // Update the title if it has changed.
            if habitTitle != habit.title {
                try await viewModel.editHabit(habit, newTitle: habitTitle)
            }
            // Update the frequency if it has changed.
            if selectedFrequency != habit.interval {
                try await viewModel.editInterval(habit, newInterval: selectedFrequency)
            }
            // If you want to update the description, add a corresponding method in your view model.
            // For now, we assume that editing description is not supported in the view model.
        } catch {
            print("Error saving updates: \(error.localizedDescription)")
        }
    }
}

struct EditHabitView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleHabit = Habit(
            id: "test1",
            title: "Test Habit",
            interval: [1, 3, 5],
            description: "A sample habit",
            startDate: Date(),
            completedDates: []
        )
        EditHabitView(habit: sampleHabit)
            .environmentObject(HabitViewModel())
    }
} 