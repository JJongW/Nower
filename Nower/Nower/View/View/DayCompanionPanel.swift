//
//  DayCompanionPanel.swift
//  Nower (macOS)
//
//  넓은 창에서 캘린더 우측에 상시 노출되는 Companion 패널.
//  선택한 날(없으면 오늘)의 밀도 카드 + 하루 끝 체감 1탭 캡처 + 그날 일정 상세,
//  그리고 이번 달 에너지 리포트 진입을 보여준다.
//  iOS는 칩+시트지만, macOS는 공간이 넓어 숨기지 않고 곁에 둔다.
//

import SwiftUI
#if canImport(NowerCore)
import NowerCore
#endif

struct DayCompanionPanel: View {
    @EnvironmentObject var viewModel: CalendarViewModel

    /// 체감 저장 후 보정/리포트를 다시 읽기 위한 재계산 트리거
    @State private var refreshToken = 0
    @State private var showMonthlyReport = false

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
            DensityCardView(state: NowerDensity.relativeViewState(
                todosProvider: { viewModel.todos(for: $0) }, day: day, reflections: reflections
            ))

            if canReflect {
                reflectionSection
            }

            reportButton
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
        #if canImport(NowerCore)
        .sheet(isPresented: $showMonthlyReport) {
            monthlyReportSheet
        }
        #endif
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

    #if canImport(NowerCore)

    // MARK: - 체감 1탭 캡처

    /// 체감을 물어볼 수 있는 날(오늘 이전 + 일정 있음)
    private var canReflect: Bool {
        let cal = Calendar.current
        return cal.startOfDay(for: day) <= cal.startOfDay(for: Date()) && !todos.isEmpty
    }

    /// store 재조회 (refreshToken으로 재계산 트리거)
    private var reflections: [DayReflection] {
        _ = refreshToken
        return DependencyContainer.shared.reflectionStore.all()
    }

    private var existingFelt: DensityBand? {
        _ = refreshToken
        return DependencyContainer.shared.reflectionStore.reflection(for: day)?.feltBand
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(reflectionDayTitle), 어땠어요?")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(existingFelt == nil
                 ? "느낌을 한 번 눌러두면 다음 점수가 더 정확해져요."
                 : "기록됐어요. 바꾸려면 다시 골라주세요.")
                .font(.system(size: 11))
                .foregroundColor(AppColors.textFieldPlaceholder)

            HStack(spacing: 8) {
                ForEach([DensityBand.light, .moderate, .heavy], id: \.self) { band in
                    bandButton(band)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.todoBackground.opacity(0.5))
        )
    }

    private func bandButton(_ band: DensityBand) -> some View {
        let selected = existingFelt == band
        let color = Color(densityHex: band.colorHex)
        return Button {
            saveReflection(band)
        } label: {
            Text(band.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? color : color.opacity(0.14))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(band.label)로 체감 기록")
    }

    private func saveReflection(_ band: DensityBand) {
        let base = NowerDensity.report(todos: viewModel.todos(for: day), day: day)
        let reflection = DayReflection(
            date: Calendar.current.startOfDay(for: day),
            feltBand: band,
            predictedScore: base.score,
            predictedBand: base.band,
            note: nil,
            createdAt: Date()
        )
        DependencyContainer.shared.reflectionStore.upsert(reflection)
        // 체감을 남긴 시점에 도달 마일스톤을 '알림 완료' 처리(패널이 상시 노출이라 깜빡임 방지)
        NowerDensity.acknowledgeMilestones(
            todosProvider: { viewModel.todos(for: $0) },
            day: day,
            reflections: DependencyContainer.shared.reflectionStore.all()
        )
        refreshToken += 1
    }

    // MARK: - 월간 리포트 진입

    private var reportButton: some View {
        Button {
            showMonthlyReport = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                Text("이번 달 에너지 리포트")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.textFieldPlaceholder)
            }
            .foregroundColor(AppColors.textPrimary)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.todoBackground.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }

    private var monthlyReportSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("닫기") { showMonthlyReport = false }
                    .buttonStyle(.plain)
                    .foregroundColor(AppColors.textHighlighted)
                    .padding(12)
            }
            MonthlyEnergyReportView(report: monthlyReport, monthTitle: monthTitle)
        }
        .frame(width: 420, height: 560)
        .background(AppColors.background)
    }

    private var monthlyReport: MonthlyEnergyReport {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        let comps = calendar.dateComponents([.year, .month], from: day)
        let first = calendar.date(from: comps) ?? day
        let range = calendar.range(of: .day, in: .month, for: day) ?? (1..<29)
        let days: [Date] = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
        return NowerDensity.monthlyEnergyReport(
            month: day,
            days: days,
            todosProvider: { viewModel.todos(for: $0) },
            reflections: reflections
        )
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: day)
    }

    private var reflectionDayTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "오늘" }
        if cal.isDateInYesterday(day) { return "어제" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: day)
    }

    #endif

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
