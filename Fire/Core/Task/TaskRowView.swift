//
//  TaskRowView.swift
//  Fire
//
//  Created by Oliver Tran on 1/27/25.
//

import SwiftUI

struct TaskRowView: View {
    let task: Todo
    let onComplete: () -> Void
    let onDelete: (() -> Void)?
    let onDueDate: (() -> Void)?

    var body: some View {
        HStack {
            Button(action: onComplete) {
                Image(systemName: task.isComplete ? "checkmark.square" : "square")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .font(.system(size: 25))
            }
            .buttonStyle(BorderlessButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .fontWeight(task.isComplete ? .light : .regular)

                if task.isComplete, let dateCompleted = task.dateCompleted {
                    Text("Completed on \(dateCompleted, formatter: Utilities.dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if let dueDate = task.dueDate {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let taskDate = calendar.startOfDay(for: dueDate)

                    if taskDate < today {
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if taskDate == today {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else if taskDate == calendar.date(byAdding: .day, value: 1, to: today) {
                        Text("Tomorrow")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    } else {
                        Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            if let onDueDate = onDueDate {
                Button(action: onDueDate) {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.trailing)
            }

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}
