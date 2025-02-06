import SwiftUI

struct TaskActionSheet: View {
    @State private var editedTitle: String
    var task: Todo
    @Binding var isPresented: Bool
    let onDelete: (() -> Void)?
    let onDueDate: (() -> Void)?
    let online: Bool
    @EnvironmentObject var viewModel: TaskViewModel
    
    init(task: Todo, isPresented: Binding<Bool>, onDelete: (() -> Void)?, onDueDate: (() -> Void)?, online: Bool) {
        self.task = task
        self._isPresented = isPresented
        self.onDelete = onDelete
        self.onDueDate = onDueDate
        self.online = online
        self._editedTitle = State(initialValue: task.title)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Task Title")
                            .font(.headline)) {
                    VStack(spacing: 12) {
                        TextField("Edit Task Title", text: $editedTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .submitLabel(.done)
                            .onSubmit {
                                Task { await saveTask() }
                            }
                        
                        Button(action: {
                            Task { await saveTask() }
                        }) {
                            Text("Save")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(online ? Color.blue : Color.gray)
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        .disabled(!online || editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.vertical, 8)
                }
                
                if let onDueDate = onDueDate {
                    Section {
                        Button(action: {
                            isPresented = false
                            onDueDate()
                        }) {
                            Label("Set Due Date", systemImage: "calendar")
                        }
                        .disabled(!online)
                    }
                }
                
                if let onDelete = onDelete {
                    Section {
                        Button(role: .destructive, action: {
                            isPresented = false
                            onDelete()
                        }) {
                            Label("Delete Task", systemImage: "trash")
                        }
                        .disabled(!online)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Task Options")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
    
    private func saveTask() async {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        do {
            try await viewModel.editTask(task, newTitle: trimmedTitle)
            // Dismiss the action sheet after saving.
            isPresented = false
            editedTitle = ""
        } catch {
            // Handle error appropriately, e.g. log it or show an alert.
            print("Error updating task: \(error)")
        }
    }
} 
