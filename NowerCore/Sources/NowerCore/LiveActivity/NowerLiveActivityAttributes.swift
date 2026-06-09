//
//  NowerLiveActivityAttributes.swift
//  NowerCore
//
//  Live Activity(잠금화면/Dynamic Island) Companion UI의 상태 모델.
//  앱과 위젯 익스텐션이 공유한다. ActivityKit이 없는 플랫폼에서는 컴파일되지 않는다.
//
//  원칙: Live Activity는 "정확한 시간 알림"의 주 수단이 아니다.
//        시간 알림은 Local Notification이 담당하고, 여기서는 다음 일정·남은 시간·
//        집중 블록·이동 준비 등을 조용히 보여주는 보조 Companion UI로만 쓴다.
//

#if os(iOS)
import ActivityKit
import Foundation

@available(iOS 16.1, *)
public struct NowerLiveActivityAttributes: ActivityAttributes {

    /// 실시간으로 갱신되는 상태
    public struct ContentState: Codable, Hashable {
        /// 일정 제목
        public var eventTitle: String
        /// 기준 일정 시작 일시 (카운트다운 기준)
        public var eventDate: Date
        /// 시작 시각 표기 ("15:00")
        public var startTime: String
        /// Companion 상태 (다음 일정 / 이동 준비 / 집중 블록 / 회복 / 과부하)
        public var mode: Mode
        /// 보조 문구 ("이동 준비", "집중 중" 등). 없으면 nil
        public var detail: String?

        public init(
            eventTitle: String,
            eventDate: Date,
            startTime: String,
            mode: Mode,
            detail: String? = nil
        ) {
            self.eventTitle = eventTitle
            self.eventDate = eventDate
            self.startTime = startTime
            self.mode = mode
            self.detail = detail
        }
    }

    /// Companion 상태 종류
    public enum Mode: String, Codable, Hashable {
        case upcoming     // 다음 일정까지 남은 시간
        case travelPrep   // 이동 준비 카운트다운
        case focusBlock   // 집중 블록 진행 중
        case recovery     // 일정 사이 회복 시간
        case overload     // 오늘 과부하 구간 안내

        /// 표시 라벨
        public var label: String {
            switch self {
            case .upcoming: return "다음 일정"
            case .travelPrep: return "이동 준비"
            case .focusBlock: return "집중 중"
            case .recovery: return "회복 시간"
            case .overload: return "과부하 구간"
            }
        }

        /// SF Symbol 이름
        public var symbol: String {
            switch self {
            case .upcoming: return "calendar"
            case .travelPrep: return "figure.walk"
            case .focusBlock: return "brain.head.profile"
            case .recovery: return "cup.and.saucer"
            case .overload: return "exclamationmark.triangle"
            }
        }
    }

    /// 고정 속성 — 하루 밀도 라벨 ("여유"/"보통"/"과부하")
    public var densityLabel: String

    public init(densityLabel: String) {
        self.densityLabel = densityLabel
    }
}
#endif
