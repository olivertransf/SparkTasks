//
//  TimerView.swift
//  Fire
//
//  Created by Oliver Tran on 1/24/25.
//

import SwiftUI

struct TimerView: View {
    
    @StateObject private var viewModel = TimerViewModel()

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                if !viewModel.recentDescriptions.isEmpty {
                    Picker("Recent Descriptions", selection: $viewModel.description) {
                        Text("Description").tag("")
                        ForEach(viewModel.recentDescriptions, id: \.self) { description in
                            Text(description).tag(description)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                }
                TextField("Description", text: $viewModel.description)
                    .textFieldStyle(.roundedBorder)
                    .padding()
            }

            // Timer Display
            Text(viewModel.timeString)
                .font(.largeTitle)
                .monospacedDigit()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            // Timer Controls
            VStack {
                Button(action: viewModel.start) {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isRunning)

                Button(action: viewModel.pause) {
                    Text("Pause")
                        .frame(maxWidth: .infinity)
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
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasStarted)
            }
            .padding(.horizontal)

            VStack() {
                HStack {
                    Text("Timers Log")
                        .font(.headline)
                    
                    if !viewModel.recentDescriptions.isEmpty {
                        Picker("Recent Descriptions", selection: $viewModel.filterText) {
                            Text("Select a Filter").tag("") // Default text option
                            ForEach(viewModel.recentDescriptions, id: \.self) { description in
                                Text(description).tag(description)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                List {
                    ForEach(viewModel.filteredTimers, id: \.timestamp) { timer in
                        HStack {
                            // Checkmark for selected timers
                            Image(systemName: viewModel.selectedTimers.contains(timer) ? "checkmark.circle.fill" : "circle")
                                .onTapGesture {
                                    if viewModel.selectedTimers.contains(timer) {
                                        viewModel.selectedTimers.remove(timer)
                                    } else {
                                        viewModel.selectedTimers.insert(timer)
                                    }
                                }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time Elapsed: \(viewModel.formatTime(from: timer.elapsedTime))")
                                    .font(.body)
                                    .monospacedDigit()

                                Text("Description: \(timer.description)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Text("Start Time: \(viewModel.formatDate(from: timer.startTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("End Time: \(viewModel.formatDate(from: timer.endTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .refreshable {
                    Task {
                        do {
                            try await viewModel.fetchPreviousTimers()
                        } catch {
                            print("Failed to load user or timers: \(error.localizedDescription)")
                        }
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
