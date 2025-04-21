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

struct HolidayItems: Decodable {
    let item: [Holiday]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let _ = try? container.decode(String.self) {
            self.item = []
            return
        }

        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        if let array = try? keyed.decode([Holiday].self, forKey: .item) {
            self.item = array
        } else if let single = try? keyed.decode(Holiday.self, forKey: .item) {
            self.item = [single]
        } else {
            self.item = []
        }
    }

    private enum CodingKeys: String, CodingKey {
        case item
    }
}

struct Holiday: Decodable {
    let dateName: String
    let locdate: Int

    var locdateString: String {
        String(locdate)
    }
}

