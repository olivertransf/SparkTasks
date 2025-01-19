import SwiftUI

struct TaskRowView: View {
    let task: Todo
    let onComplete: () -> Void
    let onDelete: (() -> Void)?
    let onDueDate: (() -> Void)?

    var body: some View {
        HStack {
            Button(action: onComplete) {
                Image(systemName: task.isComplete ? "checkmark.square" : "square")
            }
            .buttonStyle(BorderlessButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isComplete)
                    .fontWeight(task.isComplete ? .light : .regular)

                if task.isComplete, let dateCompleted = task.dateCompleted {
                    Text("Completed on \(dateCompleted, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if let dueDate = task.dueDate {
                    // Show due date logic for incomplete tasks
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let taskDate = calendar.startOfDay(for: dueDate)

                    if taskDate < today {
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if taskDate == today {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else if taskDate == calendar.date(byAdding: .day, value: 1, to: today) {
                        Text("Tomorrow")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    } else {
                        Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            if let onDueDate = onDueDate {
                Button(action: onDueDate) {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding()
            }

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .padding()
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

struct TaskView: View {
    @Binding var showSignInView: Bool
    @StateObject private var viewModel = TaskViewModel()
    @StateObject var profileViewModel = ProfileViewModel()
    @State private var taskTitle: String = ""
    @State private var showDueDatePicker: Bool = false
    @State private var selectedTask: Todo?
    @State private var selectedDate: Date = Date()

    var body: some View {
        TabView {
            NavigationView {
                VStack(spacing: 0) {
                    if viewModel.user != nil {
                        taskList
                        taskInputField
                    } else {
                        VStack {
                            Text("User is loading...")
                                .font(.title)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                        }
                    }
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
                            .background(Color.blue)
                            .foregroundColor(.white)
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
                            print("Failed to load user: \(error)")
                        }
                    }
                }
                .navigationTitle("Tasks")
            }
            .tabItem {
                Image(systemName: "checklist")
                Text("Tasks")
            }

            NavigationView {
                VStack {
                    completedTaskList
                }
                .navigationTitle("Completed")
            }
            .tabItem {
                Image(systemName: "checkmark.square")
                Text("Completed")
            }
            
            NavigationView {
                VStack {
                    Text("Habits")
                        .font(.headline)
                }
                .navigationTitle(Text("Habits"))
            }
            .tabItem {
                Image(systemName: "star")
                Text("Habits")
            }

            NavigationView {
                VStack {
                    profileView
                }
                .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Task Input Field
    private var taskInputField: some View {
        HStack {
            TextField("Enter your task...", text: $taskTitle)
                .padding()
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
        .cornerRadius(12)
        .padding([.leading, .bottom, .trailing])
    }
    
    var profileView: some View {
        List {
            if let user = viewModel.user {
                Text("UserID: \(user.userId)")
                Text("Email: \(user.email ?? "Not Set")")
                
                if let dateCreated = user.dateCreated {
                    Text("Date Created: \(dateCreated.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            NavigationLink(destination: SettingsView(showSignInView: $showSignInView)) {
                Image(systemName: "gear")
                    .font(.system(size: 30))
                    .foregroundColor(.primary)
                    .padding(.vertical)
                Text("Settings")
            }
        }
        .task {
            try? await viewModel.loadCurrentUser()
        }
        .padding(.horizontal)
        .navigationTitle(Text("Profile"))
    }
    
    
    // MARK: - Task List
    private var taskList: some View {
        VStack {
            List {
                taskSection(title: "Tasks", tasks: viewModel.tasks)
            }
            .refreshable {
                do {
                    try await viewModel.fetchTasks()
                    viewModel.sortTasks()
                } catch {
                    print("Failed to refresh tasks: \(error)")
                }
            }
            .padding()
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
            .padding()
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
    RootView()
}
