//
//  ContentView.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import SwiftUI
import Foundation
#if canImport(NowerCore)
import NowerCore
#endif

struct ContentView: View {
    let days: [String] = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    #if os(macOS)
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.openAddScheduleWithDate) private var openAddScheduleWithDate
    #endif
    @StateObject private var syncViewModel = SyncStatusViewModel()
    @State private var newTodoText: String = ""
    @State private var selectedDate: String? = nil
    @State private var selectedColor: String = ""
    @State private var isPopupVisible: Bool = false
    @State private var addEventInitialDate: Date? = nil

    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var showDensityDetail: Bool = false
    
    // 안전하게 일일 명언 로드
    private var todayQuote: String {
        DailyQuoteManager.getTodayQuote()
    }

    var body: some View {
        ZStack {
            AppColors.background
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    isPopupVisible = false
                }
                #if os(macOS)
                .onTapGesture(count: 2) {
                    if let open = openAddScheduleWithDate {
                        open(nil)
                    } else {
                        addEventInitialDate = nil
                        isPopupVisible = true
                    }
                }
                #endif
                .onAppear {
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
            GeometryReader { geo in
                let wide = isWideLayout(geo.size.width)
                HStack(spacing: 0) {
                    calendarColumn(showDensityChip: !wide)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: wide ? 8 : 20))

                    if wide {
                        Divider()
                        DayCompanionPanel()
                            .environmentObject(viewModel)
                            .frame(width: 320)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Popup for adding events (날짜 더블클릭 시 해당 날짜로 열림)
            if isPopupVisible {
                PopupBackgroundView(isPresented: $isPopupVisible) {
                    AddEventView(
                        initialDate: addEventInitialDate,
                        selectedColor: $selectedColor,
                        isPopupVisible: $isPopupVisible
                    )
                    .environmentObject(viewModel)
                }
                .onDisappear { addEventInitialDate = nil }
            }

            // Popup for conflict resolution
            if syncViewModel.showConflicts {
                PopupBackgroundView(isPresented: $syncViewModel.showConflicts) {
                    ConflictResolutionView(
                        viewModel: syncViewModel,
                        isPresented: $syncViewModel.showConflicts
                    )
                }
            }
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        #if os(macOS)
        .frame(minWidth: 700, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        #endif
        #if os(macOS)
        .onChange(of: isPopupVisible) { visible in
            NotificationCenter.default.post(
                name: visible ? .nowerPopupOpened : .nowerPopupClosed,
                object: nil
            )
        }
        #endif
    }

    /// 넓은 창 = 캘린더 + Companion 패널 split. 좁거나 데스크톱 위젯 모드면 compact.
    private func isWideLayout(_ width: CGFloat) -> Bool {
        #if os(macOS)
        if settingsManager.isDesktopMode { return false }
        #endif
        return width >= 880
    }

    /// 좌측 캘린더 컬럼 (헤더 + 요일 + 그리드). 밀도 칩은 compact 모드에서만 노출.
    @ViewBuilder
    private func calendarColumn(showDensityChip: Bool) -> some View {
        VStack(spacing: 0) {
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

                    #if canImport(NowerCore)
                    // 밀도 칩 — compact(좁은 창)에서만. 넓은 창은 Companion 패널이 대신.
                    if showDensityChip {
                        DensityChipView(
                            state: NowerDensity.viewState(
                                todos: viewModel.todos(for: viewModel.selectedDate ?? Date()),
                                day: viewModel.selectedDate ?? Date()
                            )
                        ) {
                            showDensityDetail.toggle()
                        }
                        .popover(isPresented: $showDensityDetail, arrowEdge: .bottom) {
                            DensityCardView(
                                state: NowerDensity.viewState(
                                    todos: viewModel.todos(for: viewModel.selectedDate ?? Date()),
                                    day: viewModel.selectedDate ?? Date()
                                )
                            )
                            .frame(width: 320)
                            .padding(16)
                        }
                    }
                    #endif

                    #if os(macOS)
                    if openAddScheduleWithDate == nil {
                        Button(action: {
                            settingsManager.isDesktopMode.toggle()
                        }) {
                            Image(systemName: settingsManager.isDesktopMode ? "pin.fill" : "pin")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(settingsManager.isDesktopMode ? AppColors.textHighlighted : AppColors.textPrimary)
                        }
                        .buttonStyle(.borderless)
                        .help(settingsManager.isDesktopMode ? "배경화면 고정 해제" : "배경화면 고정")
                    }
                    #endif

                    SyncStatusView(viewModel: syncViewModel)

                    Button(action: {
                        #if os(macOS)
                        if let open = openAddScheduleWithDate {
                            open(nil)
                        } else {
                            addEventInitialDate = nil
                            isPopupVisible = true
                        }
                        #else
                        addEventInitialDate = nil
                        isPopupVisible = true
                        #endif
                    }) {
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

                Text(todayQuote)
                    .foregroundColor(AppColors.textPrimary)
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 12, leading: 20, bottom: 16, trailing: 20))
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(alignment: .leading)

            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(days, id: \..self) { day in
                    Text(day)
                        .foregroundColor(day == "SUN" ? AppColors.coralred : (day == "SAT" ? AppColors.skyblue : AppColors.textPrimary))
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 4)
            .padding(.horizontal, 8)

            // Calendar Grid
            CalendarGridView(
                toastMessage: $toastMessage,
                showToast: $showToast,
                onOpenAddEventForDate: { dateString in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: dateString) {
                        #if os(macOS)
                        if let open = openAddScheduleWithDate {
                            open(date)
                        } else {
                            addEventInitialDate = date
                            isPopupVisible = true
                        }
                        #else
                        addEventInitialDate = date
                        isPopupVisible = true
                        #endif
                    }
                }
            )
            .environmentObject(viewModel)
        }
    }

    func getMonthYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy MMM" // iOS 스타일: "26 Jan"
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
            .environmentObject(CalendarViewModel())
            #if os(macOS)
            .environmentObject(SettingsManager())
            #endif
    }
}
