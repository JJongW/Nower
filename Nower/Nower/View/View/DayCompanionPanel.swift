//
//  DayCompanionPanel.swift
//  Nower (macOS)
//
//  넓은 창에서 캘린더 우측에 상시 노출되는 Companion 패널.
//  선택한 날(없으면 오늘)의 밀도 카드 + 그날 일정 상세를 보여준다.
//  iOS는 칩+팝오버지만, macOS는 공간이 넓어 숨기지 않고 곁에 둔다.
//

import SwiftUI
#if canImport(NowerCore)
import NowerCore
#endif

struct DayCompanionPanel: View {
    @EnvironmentObject var viewModel: CalendarViewModel

    private var day: Date { viewModel.selectedDate ?? Date() }

    private var todos: [TodoItem] {
        viewModel.todos(for: day).sorted { a, b in
            switch (a.scheduledTime, b.scheduledTime) {
            case let (x?, y?): return x < y
            case (nil, _?): return false
            case (_?, nil): return true
            default: return a.text < b.text
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            #if canImport(NowerCore)
            DensityCardView(state: NowerDensity.viewState(todos: viewModel.todos(for: day), day: day))
            #endif

            Divider()

            HStack {
                Text("일정")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textFieldPlaceholder)
                Spacer()
                Text("\(todos.count)개")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textFieldPlaceholder)
            }

            if todos.isEmpty {
                Text("이 날은 비어 있어요.")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textFieldPlaceholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(todos, id: \.id) { todo in
                            eventRow(todo)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColors.background)
    }

    // 날짜 헤더
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(isToday ? "오늘" : weekdayText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textHighlighted)
            Text(dateText)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private func eventRow(_ todo: TodoItem) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(AppColors.color(for: todo.colorName))
                .frame(width: 4, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                Text(todo.scheduledTime ?? "하루 종일")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textFieldPlaceholder)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.todoBackground.opacity(0.5))
        )
    }

    // MARK: - 날짜 텍스트

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"
        return f.string(from: day)
    }

    private var weekdayText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "EEEE"
        return f.string(from: day)
    }
}
