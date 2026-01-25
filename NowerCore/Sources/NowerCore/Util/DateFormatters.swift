//
//  DateFormatters.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 공통 날짜 포매터
public enum DateFormatters {
    // MARK: - Shared Formatters (Thread-safe)

    /// yyyy-MM-dd 형식 (ISO 날짜)
    public static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// yyyy-MM-dd HH:mm 형식
    public static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// HH:mm 형식 (시간만)
    public static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// 한국어 날짜 (M월 d일)
    public static let koreanDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 한국어 요일 (E요일)
    public static let koreanWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E요일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 한국어 전체 날짜 (yyyy년 M월 d일 E요일)
    public static let koreanFullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 E요일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 한국어 월 (yyyy년 M월)
    public static let koreanMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 상대적 날짜 표시 (오늘, 어제, 내일 등)
    public static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}

// MARK: - Date Extensions

public extension Date {
    /// yyyy-MM-dd 형식 문자열로 변환
    func toDateString() -> String {
        DateFormatters.isoDate.string(from: self)
    }

    /// HH:mm 형식 문자열로 변환
    func toTimeString() -> String {
        DateFormatters.time.string(from: self)
    }

    /// yyyy-MM-dd HH:mm 형식 문자열로 변환
    func toDateTimeString() -> String {
        DateFormatters.dateTime.string(from: self)
    }

    /// 한국어 날짜 문자열 (M월 d일)
    func toKoreanDateString() -> String {
        DateFormatters.koreanDate.string(from: self)
    }

    /// 한국어 전체 날짜 문자열
    func toKoreanFullDateString() -> String {
        DateFormatters.koreanFullDate.string(from: self)
    }

    /// 한국어 월 문자열 (yyyy년 M월)
    func toKoreanMonthString() -> String {
        DateFormatters.koreanMonth.string(from: self)
    }

    /// 상대적 날짜 문자열 (오늘, 어제, 3일 후 등)
    func toRelativeString() -> String {
        DateFormatters.relative.localizedString(for: self, relativeTo: Date())
    }

    /// 오늘인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 어제인지 확인
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// 내일인지 확인
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// 이번 주인지 확인
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// 이번 달인지 확인
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// 주말인지 확인
    var isWeekend: Bool {
        Calendar.current.isDateInWeekend(self)
    }

    /// 요일 번호 (1=일요일, 7=토요일)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    /// 일자 (1-31)
    var day: Int {
        Calendar.current.component(.day, from: self)
    }

    /// 월 (1-12)
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// 년도
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// 시간 (0-23)
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    /// 분 (0-59)
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    /// 특정 시간을 설정한 새 Date 반환
    func at(hour: Int, minute: Int = 0, second: Int = 0) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components) ?? self
    }

    /// 날짜 시작 (00:00:00)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 날짜 끝 (23:59:59)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// 월 시작일
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// 월 마지막일
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }
}

// MARK: - String Extensions

public extension String {
    /// yyyy-MM-dd 문자열을 Date로 변환
    func toDate() -> Date? {
        DateFormatters.isoDate.date(from: self)
    }

    /// yyyy-MM-dd HH:mm 문자열을 Date로 변환
    func toDateTime() -> Date? {
        DateFormatters.dateTime.date(from: self)
    }
}
