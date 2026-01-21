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
    
    // 안전하게 일일 명언 로드
    private var todayQuote: String {
        DailyQuoteManager.getTodayQuote()
    }

    var body: some View {
            ZStack {
            // Dismiss popup on background tap
            AppColors.background
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    isPopupVisible = false
                }
                .onAppear {
                    // View가 나타날 때 초기화 보장
                    if viewModel.weeks.isEmpty {
                        viewModel.generateCalendarDays(for: viewModel.currentMonth)
                    }
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
                // 이 영역은 창 이동을 허용하지 않음 (타이틀바에서만 이동 가능)
                VStack {
                    HStack {
                        Text(getMonthYear(from: viewModel.currentMonth))
                            .font(.title).bold()
                            .foregroundColor(AppColors.textColor1)

                        Button(action: { viewModel.changeMonth(by: -1) }) {
                            AppIcons.leftArrow
                                .foregroundColor(AppColors.textPrimary)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .buttonStyle(.borderless)
                        .help("이전 달")

                        Button(action: { viewModel.changeMonth(by: 1) }) {
                            AppIcons.rightArrow
                                .foregroundColor(AppColors.textPrimary)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .buttonStyle(.borderless)
                        .help("다음 달")

                        Spacer()

                        Button(action: { isPopupVisible = true }) {
                            Text("Add Event")
                                .foregroundColor(AppColors.buttonTextColor)
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(AppColors.buttonBackground)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()

                    // iOS 버전과 동일하게 일일 명언 표시
                    Text(todayQuote)
                        .foregroundColor(AppColors.textPrimary)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 8, leading: 20, bottom: 32, trailing: 20))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .frame(alignment: .leading)

                // Weekday Headers
                // CalendarGridView와 동일한 패딩을 적용하여 정렬 일치
                HStack(spacing: 0) {
                    ForEach(days, id: \..self) { day in
                        Text(day)
                            .foregroundColor(day == "SUN" ? AppColors.holidayHighlight : AppColors.textColor1)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
                .padding(.horizontal, 8) // CalendarGridView와 동일한 horizontal padding 적용

                // Calendar Grid
                CalendarGridView(toastMessage: $toastMessage, showToast: $showToast)
                    .environmentObject(viewModel)
            }
            .frame(width: 1024, height: 720)
            .padding(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))

            // Popup for adding events
            if isPopupVisible {
                PopupBackgroundView(isPresented: $isPopupVisible) {
                    AddEventView(
                        initialDate: nil,
                        selectedColor: $selectedColor,
                        isPopupVisible: $isPopupVisible
                    )
                    .environmentObject(viewModel)
                }
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
