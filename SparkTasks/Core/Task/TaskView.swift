import SwiftUI

struct TaskView: View {
    @Binding var showSignInView: Bool
    @StateObject private var viewModel = TaskViewModel()
    @State private var taskTitle: String = ""
    @State private var section: String = "Inbox"
    @State private var sectionName: String = ""
    @State private var showDueDatePicker: Bool = false
    @State private var showCompletedTasks: Bool = false
    @State private var showAddTask: Bool = false
    @State private var selectedTask: Todo?
    @State private var selectedDate: Date = Date()
    @State private var showEmptyTaskAlert: Bool = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                taskList()
            }
            VStack {
                Spacer()
                
                HStack(spacing: 16) {
                    
                    Picker("Section", selection: $section) {
                        ForEach(viewModel.sections, id: \.self) { section in
                            Text(section)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .frame(height: 40)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                    .padding(.leading, 20)
                    
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 20)
                    .disabled(!networkMonitor.isOnline)

                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showDueDatePicker) {
            dueDatePickerSheet
        }
        .sheet(isPresented: $showCompletedTasks) {
            completedTaskListSheet
        }
        .sheet(isPresented: $showAddTask) {
            addTaskSheet
                .presentationDetents([.fraction(0.7)])
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.loadCurrentUser()
                    try await viewModel.fetchSections()
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
        .environmentObject(viewModel)
    }


    // MARK: - Task List
    func taskList() -> some View {
        Group {
            if viewModel.tasks.filter({ $0.section == section }).isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tortoise.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("Click the button to add a task")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    taskSection(title: section, tasks: viewModel.tasks.filter { $0.section == section })
                }
                .listStyle(PlainListStyle())
            }
        }
        .refreshable {
            do {
                try await viewModel.fetchTasks()
                try await viewModel.fetchSections()
                viewModel.sortTasks()
            } catch {
                print("Failed to refresh tasks: \(error)")
            }
        }
    }
    
    private var addTaskSheet: some View {
        VStack(spacing: 20) {
            // New Section UI
            VStack(alignment: .leading) {
                Text("Add New Section")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
                
                HStack {
                    TextField("New section name...", text: $sectionName)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary, lineWidth: 1))
                    
                    Button(action: {
                        guard !sectionName.isEmpty else { return }
                        Task {
                            do {
                                try await viewModel.addNewSection(sectionName: sectionName)
                                sectionName = ""
                            } catch {
                                print("Error adding new section: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        Text("Add")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    .padding(.leading)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Add New Task")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
                
                // Task Title Field
                TextField("Enter task title...", text: $taskTitle)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary, lineWidth: 1))
                    .font(.body)
                    .foregroundColor(.primary)
                    .submitLabel(.done)
                    .onSubmit(addTask)
            }
            
            // Section Picker
            HStack {
                Text("Select Section")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Picker("Section", selection: $section) {
                    ForEach(viewModel.sections, id: \.self) { section in
                        Text(section)
                            .padding(.vertical, 10)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
            
            // Action Buttons
            HStack {
                Button("Cancel") {
                    taskTitle = ""
                    showAddTask = false
                }
                .foregroundColor(.red)
                .font(.headline)
                .padding()
                
                Spacer()
                
                Button(action: { addTask() }) {
                    Text("Add Task")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
        .padding()
    }
    
    // MARK: - Completed Task List Sheet
    private var completedTaskListSheet: some View {
        NavigationView {
            List {
                taskSection(title: "Completed", tasks: viewModel.completedTasks)
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
                    onDelete: title != "Completed" ? {
                        deleteTask(task)
                    } : nil,
                    onDueDate: title != "Completed" && !task.isComplete ? {
                        selectedTask = task
                        selectedDate = task.dueDate ?? Date()
                        showDueDatePicker = true
                    } : nil,
                    online: networkMonitor.isOnline
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
                try await viewModel.addTask(taskName: taskTitle, section: section)
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
