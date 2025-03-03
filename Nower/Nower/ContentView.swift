import SwiftUI

struct ContentView: View {
    let currentDate = Date() // 현재 날짜 가져오기
    let calendar = Calendar.current

    var body: some View {
        VStack {
            Text(getMonthYearString(from: currentDate))
                .font(.title)
                .bold()
                .padding()

            CalendarGridView(date: currentDate)
                .padding()
        }
    }

    // 년-월 텍스트 변환 함수
    func getMonthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY년 MM월"
        return formatter.string(from: date)
    }
}

// 달력 UI를 표시할 서브 뷰
struct CalendarGridView: View {
    let date: Date
    let calendar = Calendar.current

    var body: some View {
        let days = getDaysInMonth(for: date)

        LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 10) {
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
}

// 미리보기 코드
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
