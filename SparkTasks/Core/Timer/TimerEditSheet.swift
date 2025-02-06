import SwiftUI

struct TimerEditSheet: View {
    let timerEntry: TimerEntry
    var onSave: (String, TimeInterval) -> Void

    @State private var timerDescription: String
    // Store duration in minutes
    @State private var timerDurationMinutes: Int  
    
    @Environment(\.dismiss) var dismiss

    init(timerEntry: TimerEntry, onSave: @escaping (String, TimeInterval) -> Void) {
        self.timerEntry = timerEntry
        self.onSave = onSave
        _timerDescription = State(initialValue: timerEntry.description)
        // Convert elapsedTime (seconds) to minutes; ensure at least 1 minute.
        let minutes = max(1, Int(timerEntry.elapsedTime / 60))
        _timerDurationMinutes = State(initialValue: minutes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Timer Description").font(.headline)) {
                    TextField("Enter description", text: $timerDescription)
                        .font(.caption)
                }
                
                Section(header: Text("Timer Duration (minutes)").font(.subheadline)) {
                    Picker("Duration", selection: $timerDurationMinutes) {
                        ForEach(1..<121) { minute in
                            Text("\(minute) minute\(minute == 1 ? "" : "s")")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity, maxHeight: 150)
                }
            }
            .navigationTitle("Edit Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Convert back to seconds.
                        onSave(timerDescription, TimeInterval(timerDurationMinutes * 60))
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct TimerEditSheet_Previews: PreviewProvider {
    static let mockTimer = TimerEntry(
        startTime: Date().timeIntervalSince1970,
        endTime: Date().timeIntervalSince1970 + 300,
        elapsedTime: 300,
        timestamp: Date(),
        description: "Focus Timer"
    )
    
    static var previews: some View {
        TimerEditSheet(timerEntry: mockTimer, onSave: { _, _ in })
    }
} 
