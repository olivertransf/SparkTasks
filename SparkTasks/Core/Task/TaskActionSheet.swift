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
                Section(header: Text("Task Title")) {
                    HStack {
                        TextField("\(task.title)", text: $editedTitle)
                            .onSubmit {
                                if !editedTitle.isEmpty {
                                    Task {
                                        do {
                                            try await viewModel.editTask(task, newTitle: editedTitle)
                                            isPresented = false
                                            editedTitle = ""
                                        } catch {
                                            print("Error updating task: \(error)")
                                        }
                                    }
                                }
                            }
                        Button {
                            if !editedTitle.isEmpty {
                                Task {
                                    do {
                                        try await viewModel.editTask(task, newTitle: editedTitle)
                                        isPresented = false
                                        editedTitle = ""
                                    } catch {
                                        print("Error updating task: \(error)")
                                    }
                                }
                            }
                        } label: {
                            Text("Save")
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderless)
                    }

                }
                
                if let onDueDate = onDueDate {
                    Button(action: {
                        isPresented = false
                        onDueDate()
                    }) {
                        Label("Set Due Date", systemImage: "calendar")
                    }
                    .disabled(!online)
                }
                
                if let onDelete = onDelete {
                    Button(role: .destructive, action: {
                        isPresented = false
                        onDelete()
                    }) {
                        Label("Delete Task", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .disabled(!online)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
} 
