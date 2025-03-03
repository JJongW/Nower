//
//  ContentView.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var currentDate = Date()
    let calendar = Calendar.current
    
    @StateObject var settingsManager = SettingsManager()
    @State var currentColor: Color

    var body: some View {
        VStack {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .padding()
                }

                Text(getMonthYearString(from: currentDate))
                    .font(.title)
                    .bold()
                    .padding()

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title)
                        .padding()
                }
            }
            
            VStack {
                WeekdayHeaderView()
                CalendarGridView(date: Date())
            }
            .padding()
        }
        .background(settingsManager.backgroundColor.opacity(settingsManager.opacity))
        .onReceive(settingsManager.$backgroundColor) { newColor in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentColor = newColor // ✅ 기존 색상 유지
                    }
                }
                .onReceive(settingsManager.$opacity) { newOpacity in
                    print("Opacity changed to \(newOpacity)")
                }
        .animation(.easeInOut(duration: 0.2), value: settingsManager.backgroundColor)
        .animation(.easeInOut(duration: 0.2), value: settingsManager.opacity)
    }

    func getMonthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY년 MM월"
        return formatter.string(from: date)
    }
    
    // 월 변경 함수
    func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }
}


// 요일 헤더 뷰
struct WeekdayHeaderView: View {
    let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .bold()
                    .foregroundColor(day == "일" ? .red : (day == "토" ? .blue : .black)) // 일요일은 빨강, 토요일은 파랑
            }
        }
        .padding(.bottom, 5)
    }
}

// 달력 날짜 UI
struct CalendarGridView: View {
    let date: Date
    let calendar = Calendar.current

    var body: some View {
        let days = getDaysInMonth(for: date)
        let firstWeekday = getFirstWeekday(for: date)

        LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 10) {
            // 첫 주의 빈 칸 추가
            ForEach(0..<firstWeekday, id: \.self) { _ in
                Text("")
                    .frame(width: 40, height: 40)
            }

            // 날짜 추가
            ForEach(days, id: \.self) { day in
                Text("\(day)")
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }

    // 현재 월의 날짜 배열 반환
    func getDaysInMonth(for date: Date) -> [Int] {
        let range = calendar.range(of: .day, in: .month, for: date)!
        return Array(range)
    }

    // 현재 월이 시작하는 요일 계산 (일요일 = 0, 월요일 = 1 ...)
    func getFirstWeekday(for date: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstDayOfMonth = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDayOfMonth) - 1
    }
}
