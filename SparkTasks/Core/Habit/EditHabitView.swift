import SwiftUI

struct EditHabitView: View {
    @State private var editedTitle: String
    @State private var editedFrequency: [Int]
    
    var habit: Habit
    @Binding var isPresented: Bool
    let online: Bool
    @EnvironmentObject var viewModel: HabitViewModel
    
    init(habit: Habit, isPresented: Binding<Bool>, online: Bool) {
        self.habit = habit
        self._isPresented = isPresented
        self.online = online
        _editedTitle = State(initialValue: habit.title)
        _editedFrequency = State(initialValue: habit.interval)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        TextField("\(habit.title)", text: $editedTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                        
                        Button {
                            submitEdit()
                        } label: {
                            Text("Save")
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                        }
                        .disabled(editedTitle.isEmpty)
                    }
                    .padding(.vertical, 8)
                }
                
                VStack {
                    Text("Select Frequency")
                        .font(.headline)
                        .padding(.bottom)
                    
                    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
                    
                    HStack(spacing: 10) {
                        ForEach(0..<7, id: \.self) { index in
                            Button(action: {
                                toggleDay(index)
                                print("Toggled day \(index), new frequency: \(editedFrequency)")
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(editedFrequency.contains(index) ? Color.blue : Color.clear)
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                    Text(daysOfWeek[index])
                                        .foregroundColor(editedFrequency.contains(index) ? .white : .blue)
                                }
                                .frame(width: 40, height: 40)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Circle())
                        }
                    }
                    
                    Button(action: saveFrequency) {
                        Text("Add Interval")
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                }
                .padding(.horizontal)
                
                Section {
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await viewModel.deleteHabit(habit)
                                isPresented = false
                            } catch {
                                print("Error deleting habit: \(error)")
                            }
                        }
                    } label: {
                        HStack {
                            Label("Delete Habit", systemImage: "trash")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    .disabled(!online)
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                editedFrequency = habit.interval
            }
        }
    }
    
    private func submitEdit() {
        if !editedTitle.isEmpty {
            Task {
                do {
                    try await viewModel.editHabit(habit, newTitle: editedTitle)
                    isPresented = false
                } catch {
                    print("Error updating habit title: \(error)")
                }
            }
        }
    }
    
    private func saveFrequency() {
        guard editedFrequency != habit.interval else { return }
        Task {
            do {
                try await viewModel.editInterval(habit, newInterval: editedFrequency)
                isPresented = false
            } catch {
                print("Error updating habit frequency: \(error)")
            }
        }
    }
    
    private func toggleDay(_ index: Int) {
        withAnimation(.easeInOut) {
            if let existingIndex = editedFrequency.firstIndex(of: index) {
                editedFrequency.remove(at: existingIndex)
            } else {
                editedFrequency.append(index)
                editedFrequency.sort()
            }
        }
    }
}
