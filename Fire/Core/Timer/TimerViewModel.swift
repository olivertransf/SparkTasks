//
//  TimerViewModel.swift
//  Fire
//
//  Created by Oliver Tran on 1/24/25.
//

import Foundation
import FirebaseFirestore

struct TimerEntry: Hashable {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let elapsedTime: TimeInterval
    let timestamp: Date
    let description: String
}

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var user: DBUser? = nil
    private var collection: CollectionReference? = nil
    @Published var previousTimers: [TimerEntry] = []

    @Published var description: String = ""
    @Published var recentDescriptions: [String] = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var hasStarted = false

    private var timer: Timer?
    private var startTime: Date?
    private var stopTime: Date?

    var timeString: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime - Double(Int(elapsedTime))) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    func deleteTimer(_ timer: TimerEntry) async throws {
        guard let collection = collection else {
            throw NSError(domain: "TimerViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User collection not loaded."])
        }

        // Find the corresponding document in Firestore and delete it
        let snapshot = try await collection.getDocuments()
        if let document = snapshot.documents.first(where: { $0.data()["startTime"] as? TimeInterval == timer.startTime }) {
            try await document.reference.delete()
        }

        // Update local timers list
        DispatchQueue.main.async {
            self.previousTimers.removeAll { $0 == timer }
        }
    }
    
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        collection = Firestore.firestore().collection("users").document(authDataResult.uid).collection("timers")
        try await fetchPreviousTimers()
    }

    func fetchPreviousTimers() async throws {
        guard let collection = collection else { return }
        let snapshot = try await collection.getDocuments()
        let timers = snapshot.documents.compactMap { doc -> TimerEntry? in
            let data = doc.data()
            guard let elapsedTime = data["elapsedTime"] as? TimeInterval,
                  let startTime = data["startTime"] as? TimeInterval,
                  let endTime = data["endTime"] as? TimeInterval,
                  let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                  let description = data["description"] as? String else {
                return nil
            }
            return TimerEntry(
                startTime: startTime,
                endTime: endTime,
                elapsedTime: elapsedTime,
                timestamp: timestamp,
                description: description
            )
        }

        DispatchQueue.main.async {
            self.previousTimers = timers.sorted(by: { $0.timestamp > $1.timestamp })
            self.recentDescriptions = Array(Set(timers.map { $0.description })).sorted()
        }
    }
    
    func start() {
        guard !isRunning else { return }
        hasStarted = true
        isRunning = true
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.elapsedTime += Date().timeIntervalSince(startTime)
            self.startTime = Date()
        }
    }

    func pause() {
        isRunning = false
        stopTime = Date()
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        elapsedTime = 0
        hasStarted = false
        startTime = nil
        stopTime = nil
    }

    func save() async throws {
        pause()
        
        guard let collection = collection else {
            throw NSError(domain: "TimerViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User collection not loaded."])
        }

        guard let startTime = startTime else {
            throw NSError(domain: "TimerViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Timer has not been started."])
        }
        guard let stopTime = stopTime else {
            throw NSError(domain: "TimerViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Timer has not been stopped."])
        }
        
        if description.isEmpty {
            description = "Untitled Action"
        }

        let timerData: [String: Any] = [
            "startTime": startTime.timeIntervalSince1970,
            "endTime": stopTime.timeIntervalSince1970,
            "elapsedTime": elapsedTime,
            "timestamp": FieldValue.serverTimestamp(),
            "description": description
        ]

        try await collection.addDocument(data: timerData)
        try await fetchPreviousTimers()
        
        if !recentDescriptions.contains(description) {
            recentDescriptions.append(description)
        }
        
        reset()
    }
    
    @Published var filterText: String = ""

    var filteredTimers: [TimerEntry] {
        if filterText.isEmpty {
            return previousTimers
        } else {
            return previousTimers.filter { $0.description.localizedCaseInsensitiveContains(filterText) }
        }
    }
    
    @Published var selectedTimers: Set<TimerEntry> = [] 

    func toggleSelectAll() {
        if selectedTimers.count == previousTimers.count {
            selectedTimers.removeAll()
        } else {
            selectedTimers = Set(previousTimers)
        }
    }

    var areAllSelected: Bool {
        return selectedTimers.count == previousTimers.count
    }
    
    // Format Elapsed Time as "MM:SS.mm"
    func formatTime(from elapsedTime: TimeInterval) -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime - Double(Int(elapsedTime))) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }

    // Format Start and End Time as Human-Readable Dates
    func formatDate(from timeInterval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // Calculate Total Elapsed Time for a Group of Timers
    func calculateTotalElapsedTime(for timers: [TimerEntry]) -> TimeInterval {
        timers.reduce(0) { $0 + $1.elapsedTime }
    }
}
