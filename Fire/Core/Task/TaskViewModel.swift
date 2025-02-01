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
    let section: String?  // New property

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case isComplete = "is_complete"
        case dueDate = "due_date"
        case dateCompleted = "date_completed"
        case section
    }

    init(id: String = UUID().uuidString,
         title: String,
         description: String? = nil,
         isComplete: Bool = false,
         dueDate: Date? = nil,
         dateCompleted: Date? = nil,
         section: String? = nil) { // New initializer parameter
        self.id = id
        self.title = title
        self.description = description
        self.isComplete = isComplete
        self.dueDate = dueDate
        self.dateCompleted = dateCompleted
        self.section = section
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.isComplete = try container.decode(Bool.self, forKey: .isComplete)
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.dateCompleted = try container.decodeIfPresent(Date.self, forKey: .dateCompleted)
        self.section = try container.decodeIfPresent(String.self, forKey: .section)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isComplete, forKey: .isComplete)
        try container.encodeIfPresent(dueDate.map { Timestamp(date: $0) }, forKey: .dueDate)
        try container.encodeIfPresent(dateCompleted.map { Timestamp(date: $0) }, forKey: .dateCompleted)
        try container.encodeIfPresent(section, forKey: .section)
    }
}

@MainActor
final class TaskViewModel: ObservableObject {
    @Published private(set) var user: DBUser? = nil
    private var collection: CollectionReference? = nil
    @Published var tasks: [Todo] = []
    @Published var completedTasks: [Todo] = []
    @Published var sections: [String] = ["Inbox"]
    @Published var section: String = "Inbox"


    func fetchTasks() async throws {
        guard let collection = collection else { return }

        let snapshot = try await collection.getDocuments()
        let allTasks = snapshot.documents.compactMap { try? $0.data(as: Todo.self) }

        self.tasks = allTasks.filter { !$0.isComplete }
        self.completedTasks = allTasks.filter { $0.isComplete }

        var fetchedSections = Array(Set(allTasks.compactMap { $0.section ?? "Inbox" }))

        if !fetchedSections.contains("Inbox") {
            fetchedSections.append("Inbox")
        }

        self.sections = fetchedSections.sorted { $0 == "Inbox" ? true : $1 != "Inbox" }
        
        sortTasks()
    }
    
    func addNewSection(sectionName: String) async throws {
            let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
            let collection = Firestore.firestore().collection("users").document(authDataResult.uid).collection("sections")
            
            try await collection.document(sectionName).setData([
                "name": sectionName
            ])
            
            try await fetchSections()
        }

    func fetchSections() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let collection = Firestore.firestore().collection("users").document(authDataResult.uid).collection("sections")

        let snapshot = try await collection.getDocuments()
        var fetchedSections = snapshot.documents.compactMap { document in
            return document.data()["name"] as? String
        }

        if !fetchedSections.contains("Inbox") {
            try await collection.document("Inbox").setData(["name": "Inbox"])
            fetchedSections.append("Inbox")
        }

        self.sections = fetchedSections.sorted { $0 == "Inbox" ? true : $1 != "Inbox" }
    }
    
    // MARK: - Load User
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        collection = Firestore.firestore().collection("users").document(authDataResult.uid).collection("tasks")
        try await fetchTasks()
    }

    // MARK: - Add Task
    func addTask(taskName: String, description: String? = nil, dueDate: Date? = nil, section: String? = nil) async throws {
        guard let collection = collection else { return }

        let assignedSection = section ?? "Inbox"

        let sectionCollection = try Firestore.firestore().collection("users").document(AuthenticationManager.shared.getAuthenticatedUser().uid).collection("sections")
        let sectionSnapshot = try await sectionCollection.document(assignedSection).getDocument()
        
        if !sectionSnapshot.exists {
            try await sectionCollection.document(assignedSection).setData(["name": assignedSection])
        }

        let newTask = Todo(title: taskName, description: description, dueDate: dueDate, section: assignedSection)
        try await collection.document(newTask.id).setData(try Firestore.Encoder().encode(newTask))

        tasks.append(newTask)

        if !sections.contains("Inbox") {
            sections.append("Inbox")
        }
    }

    // MARK: - Delete Task
    func deleteTask(task: Todo) async throws {
        guard let collection = collection else { return }
        try await collection.document(task.id).delete()

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
