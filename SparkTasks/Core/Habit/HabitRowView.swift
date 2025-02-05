import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let date: Date
    let onComplete: () -> Void
    let onDelete: () -> Void
    let online: Bool
    @State private var showEditSheet = false
    @EnvironmentObject var viewModel: HabitViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: habit.completedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(habit.completedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) ? .green : .blue)
            }
            .padding(.horizontal)
            .buttonStyle(BorderlessButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .onTapGesture {
                        showEditSheet = true
                    }
                
                if let description = habit.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .sheet(isPresented: $showEditSheet) {
            EditHabitView(
                habit: habit,
                isPresented: $showEditSheet,
                online: online
            )
            .environmentObject(viewModel)
        }
    }
} 
