//
//  ContentView.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
    let days: [String] = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    @StateObject private var viewModel = CalendarViewModel()
    @State private var newTodoText: String = ""
    @State private var selectedDate: String? = nil
    @State private var isPopupVisible: Bool = false

    var body: some View {
        ZStack {
            // Dismiss popup on background tap
            AppColors.background
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    isPopupVisible = false
                }

            VStack(spacing: 0) {
                VStack {
                    // Header
                    HStack {
                        Button(action: { viewModel.changeMonth(by: -1) }) {
                            AppIcons.leftArrow
                                .foregroundColor(AppColors.textColor1)
                        }
                        .buttonStyle(.borderless)

                        Text(getMonthYear(from: viewModel.currentMonth))
                            .font(.title).bold()
                            .foregroundColor(AppColors.textColor1)

                        Button(action: { viewModel.changeMonth(by: 1) }) {
                            AppIcons.rightArrow
                                .foregroundColor(AppColors.textColor1)
                        }
                        .buttonStyle(.borderless)

                        Spacer()

                        Button(action: { isPopupVisible = true }) {
                            Text("Add Event")
                                .foregroundColor(.white)
                                .padding()
                                .background(AppColors.buttonColor)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)

                // Weekday Headers
                HStack {
                    ForEach(days, id: \..self) { day in
                        Text(day)
                            .foregroundColor(AppColors.textColor1)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 5)

                // Calendar Grid
                CalendarGridView()
                    .environmentObject(viewModel)
            }
            .frame(width: 1024, height: 720)

            // Popup for adding events
            if isPopupVisible {
                VStack(spacing: 20) {
                    Text("Add New Event")
                        .font(.headline)
                        .foregroundColor(AppColors.textColor1)

                    DatePicker("Select Date", selection: Binding(
                        get: {
                            selectedDate.flatMap { getDate(from: $0) } ?? Date()
                        },
                        set: { newValue in
                            selectedDate = getString(from: newValue)
                        }
                    ), displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .frame(maxWidth: 300)

                    TextField("Enter event", text: $newTodoText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    HStack {
                        Button("Cancel") {
                            isPopupVisible = false
                        }
                        .foregroundColor(.red)

                        Button("Save") {
                            if let date = selectedDate, !newTodoText.isEmpty {
                                viewModel.addTodo(for: date, todo: newTodoText)
                                newTodoText = ""
                                isPopupVisible = false

                                DispatchQueue.main.async {
                                    viewModel.loadTodos()
                                }
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(AppColors.popupBackground)
                .cornerRadius(12)
                .frame(maxWidth: 400)
            }
        }
    }

    func getMonthYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    func getToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    func getDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    func getString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
