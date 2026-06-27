// 사용자 프로필 — 생년월일시 (UserDefaults 영구 저장; 웹과 달리 재입력 불필요)

import Foundation

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var year: Int
    var month: Int
    var day: Int
    var hour: Int?          // nil = 시간 미상
    var minute: Int = 0
    var gender: String      // male / female
    var calendar: String = "solar"   // solar / lunar
    var isLeapMonth: Bool = false
    var useTrueSolarTime: Bool = false
    var region: String = "서울"

    static let storageKey = "daltokkie.userProfile"

    static func load() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

/// 출생 지역 → 위경도 (점성술 ASC/MC 정밀도용). 이름은 사주 regionLongitudes와 동일하게 유지.
enum RegionCoords {
    /// (위도, 경도) — 각 시청 공식 좌표. 경도는 사주 regionLongitudes와 정합.
    static let table: [(name: String, lat: Double, lon: Double)] = [
        ("서울", 37.5665, 126.9780), ("부산", 35.1796, 129.0756), ("대구", 35.8714, 128.6014),
        ("인천", 37.4563, 126.7052), ("광주", 35.1595, 126.8526), ("대전", 36.3504, 127.3845),
        ("울산", 35.5384, 129.3114), ("세종", 36.4801, 127.2890), ("수원", 37.2636, 127.0286),
        ("제주", 33.4996, 126.5312), ("춘천", 37.8813, 127.7298), ("청주", 36.6424, 127.4890),
        ("전주", 35.8242, 127.1480), ("포항", 36.0190, 129.3435), ("창원", 35.2280, 128.6811),
        ("강릉", 37.7519, 128.8761), ("목포", 34.8118, 126.3922), ("여수", 34.7604, 127.6622),
        ("안동", 36.5684, 128.7294), ("속초", 38.2070, 128.5918),
    ]

    static var names: [String] { table.map(\.name) }

    /// 미등록 지역은 서울 폴백
    static func coords(for region: String) -> (lat: Double, lon: Double) {
        if let r = table.first(where: { $0.name == region }) { return (r.lat, r.lon) }
        return (37.5665, 126.9780)
    }
}
