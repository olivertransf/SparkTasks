import SwiftUI

struct TimerView: View {
    
    @StateObject private var viewModel = TimerViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var selectedTimerForEditing: TimerEntry? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Description Input Section
            HStack {
                if !viewModel.recentDescriptions.isEmpty {
                    Picker("Recent Descriptions", selection: $viewModel.description) {
                        Text("Description").tag("")
                        ForEach(viewModel.recentDescriptions, id: \.self) { description in
                            Text(description).tag(description)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                TextField("Enter Description", text: $viewModel.description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
            }
            
            // Timer Display
            Text(viewModel.timeString)
                .font(.system(size: 40, weight: .bold, design: .default))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
            
            // Timer Controls
            VStack(spacing: 10) {
                Button(action: viewModel.start) {
                    Text("Start Timer")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!networkMonitor.isOnline || viewModel.isRunning)
                
                Button(action: viewModel.pause) {
                    Text("Pause Timer")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isRunning)
                
                Button(action: {
                    Task {
                        do {
                            try await viewModel.save()
                            viewModel.reset()
                        } catch {
                            print("Failed to save timer: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Save & Reset")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.hasStarted)
            }
            .padding(.horizontal)
            
            // Timer Log Section
            VStack {
                HStack {
                    Text("Timers Log")
                        .font(.headline)
                    
                    if !viewModel.recentDescriptions.isEmpty {
                        Picker("Select Filter", selection: $viewModel.filterText) {
                            Text("Select Filter").tag("")
                            ForEach(viewModel.recentDescriptions, id: \.self) { description in
                                Text(description).tag(description)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                List {
                    ForEach(viewModel.filteredTimers, id: \.timestamp) { timer in
                        HStack {
                            // Checkmark button for selection.
                            Button(action: {
                                if viewModel.selectedTimers.contains(timer) {
                                    viewModel.selectedTimers.remove(timer)
                                } else {
                                    viewModel.selectedTimers.insert(timer)
                                }
                            }) {
                                Image(systemName: viewModel.selectedTimers.contains(timer) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time Elapsed: \(viewModel.formatTime(from: timer.elapsedTime))")
                                    .font(.body)
                                
                                Text("Description: \(timer.description)")
                                    .font(.body)
                                
                                Text("Start: \(viewModel.formatDate(from: timer.startTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("End: \(viewModel.formatDate(from: timer.endTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Delete Button.
                            Button(action: {
                                Task {
                                    do {
                                        try await viewModel.deleteTimer(timer)
                                    } catch {
                                        print("Failed to delete timer: \(error.localizedDescription)")
                                    }
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        // Make the row tappable for editing.
                        .contentShape(Rectangle())
                        .onTapGesture { selectedTimerForEditing = timer }
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    Task {
                        do {
                            try await viewModel.fetchPreviousTimers()
                        } catch {
                            print("Failed to load timers: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .padding(.top)
        }
        .padding()
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        // Present the edit sheet when a timer is selected.
        .sheet(item: $selectedTimerForEditing) { timer in
            TimerEditSheet(timerEntry: timer) { newDescription, newElapsedTime in
                Task {
                    do {
                        try await viewModel.updateTimer(timer, newDescription: newDescription, newElapsedTime: newElapsedTime)
                    } catch {
                        print("Failed to update timer: \(error.localizedDescription)")
                    }
                }
            }
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.loadCurrentUser()
                } catch {
                    print("Failed to load user or timers: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    TimerView()
} 