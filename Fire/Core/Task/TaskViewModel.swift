//
//  TaskManager.swift
//  Fire
//
//  Created by Oliver Tran on 1/11/25.
//

import Foundation
import FirebaseFirestore

struct Todo: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let isComplete: Bool
    let dueDate: Date?
    let dateCompleted: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case isComplete = "is_complete"
        case dueDate = "due_date"
        case dateCompleted = "date_completed"
    }

    init(id: String = UUID().uuidString,
         title: String,
         description: String? = nil,
         isComplete: Bool = false,
         dueDate: Date? = nil,
         dateCompleted: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.isComplete = isComplete
        self.dueDate = dueDate
        self.dateCompleted = dateCompleted
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.isComplete = try container.decode(Bool.self, forKey: .isComplete)
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.dateCompleted = try container.decodeIfPresent(Date.self, forKey: .dateCompleted)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isComplete, forKey: .isComplete)
        try container.encodeIfPresent(dueDate.map { Timestamp(date: $0) }, forKey: .dueDate)
        try container.encodeIfPresent(dateCompleted.map { Timestamp(date: $0) }, forKey: .dateCompleted)
    }
}

@MainActor
final class TaskViewModel: ObservableObject {
    @Published private(set) var user: DBUser? = nil
    private var collection: CollectionReference? = nil
    @Published var tasks: [Todo] = []
    @Published var completedTasks: [Todo] = []

    // MARK: - Fetch Tasks
    func fetchTasks() async throws {
        guard let collection = collection else { return }

        let snapshot = try await collection.getDocuments()
        let allTasks = snapshot.documents.compactMap { try? $0.data(as: Todo.self) }

        self.tasks = allTasks.filter { !$0.isComplete }
        self.completedTasks = allTasks.filter { $0.isComplete }
        
        sortTasks()
    }

    // MARK: - Load User
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        collection = Firestore.firestore().collection("users").document(authDataResult.uid).collection("tasks")
        try await fetchTasks()
    }

    // MARK: - Add Task
    func addTask(taskName: String, description: String? = nil, dueDate: Date? = nil) async throws {
        guard let collection = collection else { return }

        let newTask = Todo(title: taskName, description: description, dueDate: dueDate)
        try await collection.document(newTask.id).setData(try Firestore.Encoder().encode(newTask))

        // Append locally to avoid refetching
        tasks.append(newTask)
    }

    // MARK: - Delete Task
    func deleteTask(task: Todo) async throws {
        guard let collection = collection else { return }
        try await collection.document(task.id).delete()

        // Remove locally
        if task.isComplete {
            completedTasks.removeAll { $0.id == task.id }
        } else {
            tasks.removeAll { $0.id == task.id }
        }
    }

    func toggleComplete(task: Todo) async throws {
        guard let collection = collection else { return }

        let updatedCompletionStatus = !task.isComplete
        let docRef = collection.document(task.id)
        
        let newDateCompleted = updatedCompletionStatus ? Date() : nil

        try await docRef.updateData([
            Todo.CodingKeys.isComplete.rawValue: updatedCompletionStatus,
            Todo.CodingKeys.dateCompleted.rawValue: newDateCompleted as Any
        ])

        // Move task between sections without refetching
        if updatedCompletionStatus {
            tasks.removeAll { $0.id == task.id }
            completedTasks.append(Todo(id: task.id, title: task.title, description: task.description, isComplete: true, dueDate: task.dueDate, dateCompleted: newDateCompleted))
        } else {
            completedTasks.removeAll { $0.id == task.id }
            tasks.append(Todo(id: task.id, title: task.title, description: task.description, isComplete: false, dueDate: task.dueDate, dateCompleted: nil))
        }
    }

    func addDueDate(task: Todo, dueDate: Date = Date()) async throws {
        guard let collection = collection else { return }

        let docRef = collection.document(task.id)
        try await docRef.updateData([
            Todo.CodingKeys.dueDate.rawValue: Timestamp(date: dueDate)
        ])

    }

    func sortTasks() {
        tasks.sort {
            ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
        }
    }

}
