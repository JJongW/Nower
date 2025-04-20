//
//  ContentView.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
    let days: [String] = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    @StateObject private var viewModel = CalendarViewModel()
    @State private var newTodoText: String = ""
    @State private var selectedDate: String? = nil
    @State private var selectedColor: String = ""
    @State private var isPopupVisible: Bool = false

    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false

    var body: some View {
        ZStack {
            // Dismiss popup on background tap
            AppColors.background
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    isPopupVisible = false
                }
            if showToast {
                ToastView(message: toastMessage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                            }
                        }
                    }
            }
            VStack(spacing: 0) {
                // Top Headers (Month change, Add Event)
                VStack {
                    HStack {
                        Text(getMonthYear(from: viewModel.currentMonth))
                            .font(.title).bold()
                            .foregroundColor(AppColors.textColor1)

                        Button(action: { viewModel.changeMonth(by: -1) }) {
                            AppIcons.leftArrow
                                .foregroundColor(AppColors.textColor1)
                        }
                        .buttonStyle(.borderless)

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

                    Text("이번 달은 이렇게 지내보는 거 어떤가요?")
                        .foregroundColor(AppColors.textColor1)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 8, leading: 20, bottom: 32, trailing: 20))
                }
                .frame(maxWidth: .infinity)
                .frame(alignment: .leading)

                // Weekday Headers
                HStack {
                    ForEach(days, id: \..self) { day in
                        Text(day)
                            .foregroundColor(day == "SUN" ? AppColors.holidayHighlight : AppColors.textColor1)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 8)

                // Calendar Grid
                CalendarGridView(toastMessage: $toastMessage, showToast: $showToast)
                    .environmentObject(viewModel)
            }
            .frame(width: 1024, height: 720)
            .padding(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))

            // Popup for adding events
            if isPopupVisible {
                AddEventView(selectedColor: $selectedColor, isPopupVisible: $isPopupVisible)
                    .environmentObject(viewModel)
            }
        }
    }

    func getMonthYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM` yyyy"
        return formatter.string(from: date)
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

    func show(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
