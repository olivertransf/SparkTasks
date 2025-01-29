import SwiftUI
import EventKit
import FSCalendar

// MARK: - Event Model
struct Event: Identifiable, Codable {
    let id: String
    let title: String
    let date: Date
    let startTime: Date
    let endTime: Date
}

// MARK: - CalendarData Manager
class CalendarData: NSObject, ObservableObject {
    private var eventStore = EKEventStore()
    @Published var events: [Event] = []
    
    // Request full access to the calendar
    func requestAccessToCalendar(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error requesting calendar access: \(error.localizedDescription)")
                    }
                    completion(granted)
                }
            }
        } else {
            // Fallback for earlier versions
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error requesting calendar access: \(error.localizedDescription)")
                    }
                    completion(granted)
                }
            }
        }
    }
    
    // Fetch events for the specific date range
    func fetchAllEvents() {
        let currentDate = Date()
        
        // Fetch events from 1 month ago to 6 months in the future
        let pastMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!
        let sixMonthsFromNow = Calendar.current.date(byAdding: .month, value: 6, to: currentDate)!
        
        let predicate = eventStore.predicateForEvents(withStart: pastMonth, end: sixMonthsFromNow, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        self.events = ekEvents.map { event in
            Event(id: event.eventIdentifier, title: event.title, date: event.startDate, startTime: event.startDate, endTime: event.endDate)
        }
        
        // Save events to UserDefaults for persistence
        saveEventsToUserDefaults()
        
        // Observe calendar changes
        observeEventStoreChanges()
    }
    
    // Helper function to save events to UserDefaults (optional)
    private func saveEventsToUserDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(events) {
            UserDefaults.standard.set(encoded, forKey: "events")
        }
    }
    
    // Helper function to load events from UserDefaults (optional)
    func loadEventsFromUserDefaults() {
        if let savedEvents = UserDefaults.standard.object(forKey: "events") as? Data {
            let decoder = JSONDecoder()
            if let decodedEvents = try? decoder.decode([Event].self, from: savedEvents) {
                self.events = decodedEvents
            }
        }
    }
    
    // Observe changes to the event store
    private func observeEventStoreChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEventStoreChanges),
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }
    
    @objc private func handleEventStoreChanges() {
        fetchAllEvents()
    }
}

// MARK: - CalendarView
struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    @ObservedObject var calendarData = CalendarData()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack {
                // FSCalendar View
                FSCalendarView(selectedDate: $selectedDate, events: calendarData.events, colorScheme: colorScheme)
                    .frame(height: 300)
                
                // List of Events for Selected Date
                List(calendarData.events.filter { event in
                    Calendar.current.isDate(event.date, inSameDayAs: selectedDate)
                }, id: \.id) { event in
                    VStack(alignment: .leading) {
                        Text(event.title)
                            .font(.headline)
                            .accessibilityLabel("Event: \(event.title)")
                        Text("Start: \(formattedDate(event.startTime)) - End: \(formattedDate(event.endTime))")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 5)
                }
                .listStyle(.plain)
                .padding()
            }
            .onAppear {
                // Request access and fetch events when the view appears
                calendarData.requestAccessToCalendar { granted in
                    if granted {
                        calendarData.fetchAllEvents()
                    } else {
                        print("Calendar access denied")
                    }
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

// MARK: - FSCalendarView (UIViewRepresentable)
struct FSCalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date
    var events: [Event]
    var colorScheme: ColorScheme
    
    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        // Adjust calendar appearance based on the current color scheme
        let appearance = calendar.appearance
        if colorScheme == .dark {
            appearance.eventDefaultColor = UIColor.white
            appearance.selectionColor = UIColor.darkGray
            appearance.titleDefaultColor = UIColor.white
            appearance.headerTitleColor = UIColor.white
            appearance.weekdayTextColor = UIColor.lightGray
        } else {
            appearance.eventDefaultColor = UIColor.blue
            appearance.selectionColor = UIColor.lightGray
            appearance.titleDefaultColor = UIColor.black
            appearance.headerTitleColor = UIColor.black
            appearance.weekdayTextColor = UIColor.darkGray
        }
        
        return calendar
    }
    
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        uiView.select(selectedDate, scrollToDate: true)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(selectedDate: $selectedDate, events: events)
    }
    
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
        @Binding var selectedDate: Date
        var events: [Event]
        
        init(selectedDate: Binding<Date>, events: [Event]) {
            _selectedDate = selectedDate
            self.events = events
        }
        
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            self.selectedDate = date
        }
        
        func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
            return events.filter { event in
                Calendar.current.isDate(event.date, inSameDayAs: date)
            }.count
        }
        
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorFor date: Date) -> UIColor? {
            // If there are events for this date, return a blue color for the dots
            return events.contains(where: { event in
                Calendar.current.isDate(event.date, inSameDayAs: date)
            }) ? UIColor.blue : nil
        }
    }
}

// MARK: - Preview
#Preview {
    CalendarView()
}
