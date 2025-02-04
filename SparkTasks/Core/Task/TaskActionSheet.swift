import SwiftUI

struct TaskActionSheet: View {
    @State private var editedTitle: String
    let task: Todo
    @Binding var isPresented: Bool
    let onDelete: (() -> Void)?
    let onDueDate: (() -> Void)?
    let online: Bool
    
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
                    TextField("Task Title", text: $editedTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
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
                    }
                    .disabled(!online)
                }
            }
            .navigationTitle(task.title)
            .navigationBarTitleDisplayMode(.inline)
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
