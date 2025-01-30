import SwiftUI
import EventKit
import FSCalendar

// MARK: - CalendarView
struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    @ObservedObject var calendarData = CalendarData()
    @Environment(\.colorScheme) var colorScheme
    @State private var showCalendarSettings: Bool = false
    @State private var calendarAccessGranted: Bool? = nil // Track calendar access status
    
    var body: some View {
        VStack(spacing: 0) {
            FSCalendarView(selectedDate: $selectedDate, events: calendarData.events, colorScheme: colorScheme)
                .frame(height: 300)
            
            List(calendarData.events.filter { event in
                Calendar.current.isDate(event.date, inSameDayAs: selectedDate)
            }, id: \.id) { event in
                VStack(alignment: .leading) {
                    Text(event.title)
                        .font(.headline)
                    Text("Start: \(formattedDate(event.startTime)) - End: \(formattedDate(event.endTime))")
                        .font(.subheadline)
                }
                .padding(.vertical, 5)
            }
            .listStyle(.plain)
            .frame(minHeight: 200)
        }
        .sheet(isPresented: $showCalendarSettings) {
            CalendarSettings(calendarAccessGranted: $calendarAccessGranted, showCalendarSettings: $showCalendarSettings)
        }
        .onAppear {
            calendarData.requestAccessToCalendar { granted in
                DispatchQueue.main.async {
                    calendarAccessGranted = granted
                    if granted {
                        calendarData.fetchAllEvents()
                    } else {
                        print("Calendar access denied")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showCalendarSettings.toggle()
                }) {
                    Image(systemName: "gear")
                }
            }
        }
    }
    
    // Helper function to format dates
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - CalendarSettings View
struct CalendarSettings: View {
    @Binding var calendarAccessGranted: Bool?
    @Binding var showCalendarSettings: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    if let granted = calendarAccessGranted {
                        Text(granted ? "✅ Local calendar access granted" : "❌ Calendar access denied")
                            .font(.headline)
                            .foregroundColor(granted ? .green : .red)
                    } else {
                        Text("Checking calendar access...")
                    }
                }
                .listStyle(PlainListStyle())
                
                Button("Close") {
                    showCalendarSettings = false
                }
                .foregroundColor(.red)
                .padding()
            }
            .navigationTitle("Calendar Settings")
        }
    }
}

// MARK: - Preview
#Preview {
    CalendarView()
}
