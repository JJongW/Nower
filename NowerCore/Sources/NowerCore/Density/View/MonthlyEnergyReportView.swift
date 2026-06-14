//
//  MonthlyEnergyReportView.swift
//  NowerCore
//
//  월간 에너지 리포트 화면 — iOS·macOS 공유 SwiftUI.
//  MonthlyEnergyReport만 받아 렌더(순수 표현). 데이터/채점은 외부.
//  추억 스크랩북이 아니라 에너지 회고: 요약 → 부담 분포 → 체감 → 처방.
//

import SwiftUI

public struct MonthlyEnergyReportView: View {
    private let report: MonthlyEnergyReport
    private let monthTitle: String

    public init(report: MonthlyEnergyReport, monthTitle: String) {
        self.report = report
        self.monthTitle = monthTitle
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                summaryCard
                distributionCard
                if report.felt.total > 0 {
                    feltCard
                } else {
                    feltEmptyCard
                }
                if let rx = report.prescription {
                    prescriptionCard(rx)
                }
            }
            .padding(20)
        }
        .background(Color.densityCardBackground.opacity(0.0))
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("에너지 리포트")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(monthTitle)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
        }
    }

    // MARK: - 요약

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(report.narration)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            if report.calibration.isActive {
                Label(
                    "내 체감 \(report.calibration.sampleCount)일이 점수에 반영되고 있어요.",
                    systemImage: "person.crop.circle.badge.checkmark"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(card)
    }

    // MARK: - 부담 분포

    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("이번 달 부담", subtitle: "엔진이 읽은 하루 밀도")
            bar(
                light: report.density.lightCount,
                moderate: report.density.moderateCount,
                heavy: report.density.heavyCount
            )
            HStack(spacing: 16) {
                legend(.light, count: report.density.lightCount)
                legend(.moderate, count: report.density.moderateCount)
                legend(.heavy, count: report.density.heavyCount)
            }
            if let h = report.density.heaviestDay {
                Text("가장 빡빡했던 날 · \(dayNumber(h.date))일 (\(h.score)점)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(card)
    }

    // MARK: - 체감

    private var feltCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("내가 느낀 하루", subtitle: "체감 기록 \(report.felt.total)일")
            bar(
                light: report.felt.light,
                moderate: report.felt.moderate,
                heavy: report.felt.heavy
            )
            HStack(spacing: 16) {
                legend(.light, count: report.felt.light)
                legend(.moderate, count: report.felt.moderate)
                legend(.heavy, count: report.felt.heavy)
            }
            if report.heavierThanExpectedDays > 0 {
                Text("예측보다 무겁게 느낀 날 \(report.heavierThanExpectedDays)일")
                    .font(.caption)
                    .foregroundColor(Color(densityHex: DensityBand.heavy.colorHex))
            } else if report.lighterThanExpectedDays > 0 {
                Text("예측보다 가볍게 넘긴 날 \(report.lighterThanExpectedDays)일")
                    .font(.caption)
                    .foregroundColor(Color(densityHex: DensityBand.light.colorHex))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(card)
    }

    private var feltEmptyCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("내가 느낀 하루", subtitle: nil)
            Text("하루 끝에 '오늘 어땠어요?'를 한 번씩 눌러두면, 다음 달 리포트가 더 정확해져요.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(card)
    }

    // MARK: - 처방

    private func prescriptionCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.yellow.opacity(0.10))
        )
    }

    // MARK: - 공통 조각

    private func sectionTitle(_ title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// 여유/보통/과부하 비율 스택 바
    private func bar(light: Int, moderate: Int, heavy: Int) -> some View {
        let total = max(1, light + moderate + heavy)
        return GeometryReader { geo in
            HStack(spacing: 2) {
                segment(width: geo.size.width * CGFloat(light) / CGFloat(total), band: .light)
                segment(width: geo.size.width * CGFloat(moderate) / CGFloat(total), band: .moderate)
                segment(width: geo.size.width * CGFloat(heavy) / CGFloat(total), band: .heavy)
            }
        }
        .frame(height: 10)
    }

    private func segment(width: CGFloat, band: DensityBand) -> some View {
        Capsule()
            .fill(Color(densityHex: band.colorHex))
            .frame(width: max(0, width))
    }

    private func legend(_ band: DensityBand, count: Int) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color(densityHex: band.colorHex))
                .frame(width: 8, height: 8)
            Text("\(band.label) \(count)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.densityCardBackground)
    }

    private func dayNumber(_ date: Date) -> Int {
        Calendar.current.component(.day, from: date)
    }
}
