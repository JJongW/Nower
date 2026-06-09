//
//  DailyQuote.swift
//  Nower
//
//  Created by 신종원 on 1/26/25.
//  Updated for iOS compatibility on 5/12/25.
//

import Foundation

/// 일일 명언을 관리하는 매니저
/// 같은 날에는 동일한 명언을 보여주고, 날짜가 바뀌면 다른 명언을 표시합니다.
struct DailyQuoteManager {
    
    /// 명언 목록을 저장하는 구조체
    private struct QuotesResponse: Codable {
        let quotes: [String]
    }
    
    /// 현재 날짜에 해당하는 명언을 반환합니다.
    /// 같은 날에는 항상 동일한 명언을 반환하고, 날짜가 바뀌면 다른 명언을 반환합니다.
    /// - Returns: 오늘의 명언 (로드 실패 시 기본 메시지 반환)
    static func getTodayQuote() -> String {
        // 명언 목록 로드
        guard let quotes = loadQuotes(), !quotes.isEmpty else {
            return "오늘도 화이팅! 💪"
        }
        
        // 오늘 날짜를 시드로 사용하여 결정적 랜덤 선택
        let today = Calendar.current.startOfDay(for: Date())
        guard let daysSinceEpoch = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: today).day else {
            return quotes[0] // 기본값으로 첫 번째 명언 반환
        }
        
        // 날짜 기반 랜덤 인덱스 선택 (같은 날에는 항상 같은 인덱스)
        // 배열 범위를 벗어나지 않도록 안전하게 처리
        let index = abs(daysSinceEpoch) % quotes.count
        
        return quotes[index]
    }
    
    /// quotes.json 파일에서 명언 목록을 로드합니다.
    /// - Returns: 명언 배열 (로드 실패 시 nil)
    private static func loadQuotes() -> [String]? {
        // Bundle이 준비되지 않았을 수 있으므로 안전하게 처리
        guard let bundle = Bundle.main.url(forResource: "quotes", withExtension: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: bundle)
            let decoder = JSONDecoder()
            let response = try decoder.decode(QuotesResponse.self, from: data)
            
            // 빈 배열 체크
            guard !response.quotes.isEmpty else {
                return nil
            }
            
            return response.quotes
        } catch {
            return nil
        }
    }
}
