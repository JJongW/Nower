//
//  DensityDetailSheet.swift
//  Nower-iOS
//
//  밀도 칩 탭 → 바텀 시트. 밀도 카드 + 하루 끝 "체감 1탭 캡처" + 월간 리포트 진입.
//  캡처는 폼 최소(밴드 1탭) — 회고 보정 루프의 입력단.
//

import SwiftUI

#if canImport(NowerCore)
import NowerCore

struct DensityDetailSheet: View {
    let densityState: DensityViewState
    let dayTitle: String
    /// 체감을 물어볼 수 있는 날인지(오늘 이전 + 일정 있음)
    let canReflect: Bool
    /// 이미 남긴 체감(있으면 선택 표시)
    let existingFelt: DensityBand?
    /// 밴드 선택 시 저장 콜백(밴드, 메모)
    let onSaveReflection: (DensityBand, String?) -> Void
    /// 월간 에너지 리포트 열기
    let onOpenMonthlyReport: () -> Void

    @State private var note: String = ""
    @State private var savedBand: DensityBand?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DensityCardView(state: densityState)

                if canReflect {
                    reflectionSection
                }

                reportButton
            }
            .padding(16)
        }
    }

    // MARK: - 체감 1탭 캡처

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(dayTitle), 어땠어요?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(currentSelection == nil
                     ? "느낌을 한 번 눌러두면 다음 점수가 더 정확해져요."
                     : "기록됐어요. 바꾸려면 다시 골라주세요.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(bands, id: \.self) { band in
                    bandButton(band)
                }
            }

            if currentSelection == nil {
                TextField("한 줄 메모 (선택)", text: $note)
                    .font(.footnote)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.densityCardBackground)
        )
    }

    private var bands: [DensityBand] { [.light, .moderate, .heavy] }

    /// 현재 선택(이번 세션 저장분 우선, 없으면 기존 기록)
    private var currentSelection: DensityBand? { savedBand ?? existingFelt }

    private func bandButton(_ band: DensityBand) -> some View {
        let selected = currentSelection == band
        let color = Color(densityHex: band.colorHex)
        return Button {
            savedBand = band
            onSaveReflection(band, note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note)
        } label: {
            Text(band.label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(selected ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected ? color : color.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(band.label)로 체감 기록")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - 월간 리포트 진입

    private var reportButton: some View {
        Button(action: onOpenMonthlyReport) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                Text("이번 달 에너지 리포트")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.densityCardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

#endif
