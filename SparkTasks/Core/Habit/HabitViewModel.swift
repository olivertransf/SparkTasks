import Foundation
import FirebaseFirestore

extension HabitViewModel {
    func habits(for date: Date) -> [Habit] {
        habits.filter { habit in
            let weekday = Calendar.current.component(.weekday, from: date) - 1
            return habit.interval.contains(weekday)
        }
    }
}

struct Habit: Codable, Identifiable {
    let id: String
    let title: String
    let interval: [Int]
    let description: String?
    let startDate: Date
    var completedDates: [Date]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case interval
        case description
        case startDate = "start_date"
        case completedDates = "completed_dates"
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         interval: [Int] = [],
         description: String? = nil,
         startDate: Date = Date(),
         completedDates: [Date] = []) {
        self.id = id
        self.title = title
        self.interval = interval
        self.description = description
        self.startDate = startDate
        self.completedDates = completedDates
    }
}

@MainActor
final class HabitViewModel: ObservableObject {
    @Published private(set) var user: DBUser? = nil
    private var collection: CollectionReference? = nil
    @Published var habits: [Habit] = []
    
    // MARK: - Load User
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        collection = Firestore.firestore().collection("users").document(authDataResult.uid).collection("habits")
        try await fetchHabits()
    }
    

    // MARK: - Add Habit
    func addHabit(habitName: String, interval: [Int] = [], description: String? = nil) async throws {
        guard let collection = collection else { return }
        
        let newHabit = Habit(
            title: habitName,
            interval: interval,
            description: description
        )
        
        do {
            try await collection.document(newHabit.id).setData(try Firestore.Encoder().encode(newHabit))
            habits.append(newHabit)
        } catch {
            print("Error adding habit: \(error.localizedDescription)")
            throw error
        }
        
        try await fetchHabits()

    }
    
    // MARK: - Complete Habit
    func completeHabit(_ habit: Habit, _ date: Date) async throws {
        guard let collection = collection else { return }
        
        do {
            var updatedHabit = habit
            
            if let index = updatedHabit.completedDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
                updatedHabit.completedDates.remove(at: index)
            } else {
                updatedHabit.completedDates.append(date)
            }
            
            try await collection.document(habit.id).setData(try Firestore.Encoder().encode(updatedHabit))
            
            if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                habits[index] = updatedHabit
            }
        } catch {
            print("Error toggling habit completion: \(error.localizedDescription)")
            throw error
        }
        
        try await fetchHabits()
    }


    
    // MARK: - Delete Habit
    func deleteHabit(_ habit: Habit) async throws {
        guard let collection = collection else { return }
        
        do {
            try await collection.document(habit.id).delete()
            
            habits.removeAll { $0.id == habit.id }
        } catch {
            print("Error deleting habit: \(error.localizedDescription)")
            throw error
        }
        
        try await fetchHabits()

    }
    
    // MARK: - Fetch Habits
    func fetchHabits() async throws {
        guard let collection = collection else { return }
        
        do {
            let snapshot = try await collection.getDocuments()
            self.habits = try snapshot.documents.map { document in
                guard let habit = try? document.data(as: Habit.self) else {
                    throw NSError(domain: "HabitDecodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode habit with ID: \(document.documentID)"])
                }
                return habit
            }
        } catch {
            print("Error fetching habits: \(error.localizedDescription)")
            throw error
        }
    
    }
    
    
}
