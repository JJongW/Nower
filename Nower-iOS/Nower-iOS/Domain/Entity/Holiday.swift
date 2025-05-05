//
//  Holiday.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

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
