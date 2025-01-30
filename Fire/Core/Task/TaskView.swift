import SwiftUI

struct TaskView: View {
    @Binding var showSignInView: Bool
    @StateObject private var viewModel = TaskViewModel()
    @State private var taskTitle: String = ""
    @State private var showDueDatePicker: Bool = false
    @State private var showCompletedTasks: Bool = false
    @State private var selectedTask: Todo?
    @State private var selectedDate: Date = Date()
    @State private var showEmptyTaskAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            taskList
            
            Divider()
            
            taskInputField
                .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showCompletedTasks.toggle()
                }) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showDueDatePicker) {
            dueDatePickerSheet
        }
        .sheet(isPresented: $showCompletedTasks) {
            completedTaskListSheet
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.loadCurrentUser()
                } catch {
                    print("Failed to load user or timers: \(error.localizedDescription)")
                }
            }
        }
        .alert(isPresented: $showEmptyTaskAlert) {
            Alert(
                title: Text("Task Title Required"),
                message: Text("Please enter a task title before adding."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Task Input Field
    var taskInputField: some View {
        HStack {
            TextField("Add a new task...", text: $taskTitle)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .submitLabel(.done)
                .onSubmit(addTask)
            
            Button(action: addTask) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            .padding(.leading, 8)
        }
    }

    // MARK: - Task List
    var taskList: some View {
        List {
            taskSection(title: "", tasks: viewModel.tasks)
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            do {
                try await viewModel.fetchTasks()
                viewModel.sortTasks()
            } catch {
                print("Failed to refresh tasks: \(error)")
            }
        }
    }

    // MARK: - Completed Task List Sheet
    private var completedTaskListSheet: some View {
        NavigationView {
            List {
                taskSection(title: "Completed Tasks", tasks: viewModel.completedTasks)
            }
            .navigationTitle("Completed")
        }
    }

    // MARK: - Due Date Picker Sheet
    private var dueDatePickerSheet: some View {
        NavigationView {
            VStack {
                Spacer()
                
                DatePicker("Select Due Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding(.horizontal)
                
                HStack {
                    Button("Cancel") {
                        showDueDatePicker = false
                    }
                    .foregroundColor(.red)
                    .padding()
                    
                    Spacer()
                    
                    Button("Save") {
                        guard let task = selectedTask else { return }
                        Task {
                            do {
                                try await viewModel.addDueDate(task: task, dueDate: selectedDate)
                                selectedTask = nil
                                showDueDatePicker = false
                                selectedDate = Date()
                                try? await viewModel.fetchTasks()
                            } catch {
                                print("Failed to update due date: \(error)")
                            }
                        }
                    }
                    .disabled(selectedDate == Date())
                    .padding()
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Set Due Date")
        }
    }

    // MARK: - Task Section Builder
    private func taskSection(title: String, tasks: [Todo]) -> some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(tasks) { task in
                TaskRowView(
                    task: task,
                    onComplete: {
                        completeTask(task)
                    },
                    onDelete: title == "" ? {
                        deleteTask(task)
                    } : nil,
                    onDueDate: title == "" && !task.isComplete ? {
                        selectedTask = task
                        selectedDate = task.dueDate ?? Date()
                        showDueDatePicker = true
                    } : nil
                )
            }
        }
    }

    // MARK: - Helper Methods
    private func addTask() {
        guard !taskTitle.isEmpty else {
            showEmptyTaskAlert = true
            return
        }
        Task {
            do {
                try await viewModel.addTask(taskName: taskTitle)
                taskTitle = ""
                viewModel.sortTasks()
            } catch {
                print("Failed to add task: \(error)")
            }
        }
    }

    private func completeTask(_ task: Todo) {
        Task {
            do {
                try await viewModel.toggleComplete(task: task)
                viewModel.sortTasks()
            } catch {
                print("Failed to toggle completion: \(error)")
            }
        }
    }

    private func deleteTask(_ task: Todo) {
        Task {
            do {
                try await viewModel.deleteTask(task: task)
                viewModel.sortTasks()
            } catch {
                print("Failed to delete task: \(error)")
            }
        }
    }
}

#Preview {
    TaskView(showSignInView: .constant(false))
}
