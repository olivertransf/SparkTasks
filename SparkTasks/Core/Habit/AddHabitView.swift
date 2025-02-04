//
//  AddHabitView.swift
//
//  Created by Oliver Tran on 1/27/25.
//
import SwiftUI

struct AddHabitView: View {
    @Binding var habitTitle: String
    @Binding var selectedFrequency: Set<Int>
    @Binding var showAddHabitView: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add a New Habit")
                .font(.largeTitle)
                .bold()
                .padding(.top)
                .foregroundColor(.blue)
            
            TextField("Enter your habit...", text: $habitTitle)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .submitLabel(.done)
                .shadow(radius: 2)
                .padding(.horizontal)
            
            VStack {
                Text("Select Frequency")
                    .font(.headline)
                    .padding(.bottom)
                
                HStack(spacing: 10) {
                    ForEach(0..<7, id: \.self) { index in
                        let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
                        Button(action: {
                            if selectedFrequency.contains(index) {
                                selectedFrequency.remove(index)
                            } else {
                                selectedFrequency.insert(index)
                            }
                        }) {
                            Text(daysOfWeek[index])
                                .foregroundColor(selectedFrequency.contains(index) ? .white : .blue)
                                .frame(width: 40, height: 40)
                                .background(selectedFrequency.contains(index) ? Color.blue : Color.clear)
                                .cornerRadius(20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    habitTitle = ""
                    selectedFrequency = []
                    showAddHabitView = false
                }
                .foregroundColor(.red)
                .font(.headline)
                .padding()
                
                Spacer()
                
                Button(action: onSave) {
                    Text("Add Habit")
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                }
            }
            .padding()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}
