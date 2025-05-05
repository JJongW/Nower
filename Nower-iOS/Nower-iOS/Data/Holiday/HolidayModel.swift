//
//  HolidayModel.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/21/25.
//

// MARK: - 응답 모델
struct HolidayResponse: Decodable {
    let response: HolidayResponseBody
}

struct HolidayResponseBody: Decodable {
    let body: HolidayResponseData
}

struct HolidayResponseData: Decodable {
    let items: HolidayItems?

    var holidays: [Holiday] {
        items?.item ?? []
    }
}
