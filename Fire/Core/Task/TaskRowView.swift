import SwiftUI

struct TaskRowView: View {
    let task: Todo
    let onComplete: () -> Void
    let onDelete: (() -> Void)?
    let onDueDate: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onComplete()
                }
            }) {
                Image(systemName: task.isComplete ? "checkmark.square" : "square")
                    .padding(.horizontal, 8)
                    .font(.system(size: 25))
            }
            .buttonStyle(BorderlessButtonStyle())
            .accessibilityLabel(task.isComplete ? "Mark as incomplete" : "Mark as complete")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .fontWeight(task.isComplete ? .light : .regular)
                    .strikethrough(task.isComplete)
                    .foregroundColor(task.isComplete ? .gray : .primary)

                if task.isComplete, let dateCompleted = task.dateCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Completed on \(dateCompleted, formatter: Utilities.dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else if let dueDate = task.dueDate {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let taskDate = calendar.startOfDay(for: dueDate)

                    HStack {
                        if taskDate < today {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Overdue")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if taskDate == today {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.blue)
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else if taskDate == calendar.date(byAdding: .day, value: 1, to: today) {
                            Image(systemName: "sun.haze.fill")
                                .foregroundColor(.orange)
                            Text("Tomorrow")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(.vertical, 3)

            Spacer()

            if let onDueDate = onDueDate {
                Button(action: onDueDate) {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.trailing, 8)
                .accessibilityLabel("Set due date")
            }

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
                .accessibilityLabel("Delete task")
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onComplete) {
                Label("Complete", systemImage: task.isComplete ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(task.isComplete ? .orange : .green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            }
        }
    }
}
