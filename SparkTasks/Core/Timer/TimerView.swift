import SwiftUI

struct TimerView: View {
    
    @StateObject private var viewModel = TimerViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        VStack(spacing: 20) {
            
            // Description Section
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
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)

            // Timer Controls
            VStack(spacing: 10) {
                Button(action: viewModel.start) {
                    Text("Start Timer")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .font(.headline)
                }
                .disabled(!networkMonitor.isOnline)
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isRunning)

                Button(action: viewModel.pause) {
                    Text("Pause Timer")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .font(.headline)
                }
                .buttonStyle(.bordered)
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
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
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
                            Image(systemName: viewModel.selectedTimers.contains(timer) ? "checkmark.circle.fill" : "circle")
                                .onTapGesture {
                                    if viewModel.selectedTimers.contains(timer) {
                                        viewModel.selectedTimers.remove(timer)
                                    } else {
                                        viewModel.selectedTimers.insert(timer)
                                    }
                                }
                                .foregroundColor(viewModel.selectedTimers.contains(timer) ? .green : .blue)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time Elapsed: \(viewModel.formatTime(from: timer.elapsedTime))")
                                    .font(.body)
                                    .monospacedDigit()
                                    .foregroundColor(.primary)
                                
                                Text("Description: \(timer.description)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Start: \(viewModel.formatDate(from: timer.startTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("End: \(viewModel.formatDate(from: timer.endTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Delete Button
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
