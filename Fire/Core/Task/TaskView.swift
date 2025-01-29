import SwiftUI

struct TaskView: View {
    @Binding var showSignInView: Bool
    @StateObject private var viewModel = TaskViewModel()
    @State private var taskTitle: String = ""
    @State private var showDueDatePicker: Bool = false
    @State private var selectedTask: Todo?
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                taskList
                taskInputField
            }
            .sheet(isPresented: $showDueDatePicker) {
                VStack {
                    Text("Set Task Due Date")
                        .font(.headline)
                        .padding()
                    DatePicker("Select Due Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                    
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
                        .padding()
                        .cornerRadius(10)
                    }
                    .padding()
                }
                .padding()
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
        }
    }

    // MARK: - Task Input Field
    var taskInputField: some View {
        HStack {
            TextField("+ Add task to \"Tasks\"...", text: $taskTitle)
                .padding()
                .background(Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark ? .systemGray6 : .white
                }))
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
        .cornerRadius(12)
        .padding([.leading, .bottom, .trailing])
    }

    
    // MARK: - Task List
    var taskList: some View {
        VStack {
            List {
                taskSection(title: "Tasks", tasks: viewModel.tasks)
            }
            .scrollContentBackground(.hidden)
            .refreshable {
                do {
                    try await viewModel.fetchTasks()
                    viewModel.sortTasks()
                } catch {
                    print("Failed to refresh tasks: \(error)")
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    // MARK: - Completed Task List
    private var completedTaskList: some View {
        VStack {
            List {
                taskSection(title: "Completed", tasks: viewModel.completedTasks)
            }
            .refreshable {
                do {
                    try await viewModel.fetchTasks()
                    viewModel.sortTasks()
                } catch {
                    print("Failed to refresh tasks: \(error)")
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(InsetGroupedListStyle())
        }
    }

    // MARK: - Task Section Builder
    private func taskSection(title: String, tasks: [Todo]) -> some View {
        Section(title) {
            ForEach(tasks) { task in
                TaskRowView(
                    task: task,
                    onComplete: {
                        completeTask(task)
                    },
                    onDelete: title == "Tasks" ? {
                        deleteTask(task)
                    } : nil,
                    onDueDate: title == "Tasks" && !task.isComplete ? {
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
        guard !taskTitle.isEmpty else { return }
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
