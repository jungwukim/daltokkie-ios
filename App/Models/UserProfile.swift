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

/// 출생 지역 → 위경도 + IANA 타임존 (점성술 ASC/MC·사주 진태양시 정밀도용).
/// 한국 도시 이름/경도는 사주 regionLongitudes와 반드시 정합 유지(골든 픽스처 영향).
enum RegionCoords {
    struct City: Equatable {
        let name: String      // 표시명 (한국 도시는 regionLongitudes 키와 동일)
        let lat: Double
        let lon: Double
        let tz: String        // IANA 타임존 식별자
        let group: String     // 피커 섹션 (대륙/국가)
    }

    static let koreaGroup = "대한민국"

    /// 큐레이션된 세계 주요 도시. 한국 도시(시청 좌표, regionLongitudes 정합)를 먼저 둔다.
    static let table: [City] = [
        // 대한민국 — 좌표·경도 기존 유지 (사주 regionLongitudes 정합)
        City(name: "서울", lat: 37.5665, lon: 126.9780, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "부산", lat: 35.1796, lon: 129.0756, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "대구", lat: 35.8714, lon: 128.6014, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "인천", lat: 37.4563, lon: 126.7052, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "광주", lat: 35.1595, lon: 126.8526, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "대전", lat: 36.3504, lon: 127.3845, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "울산", lat: 35.5384, lon: 129.3114, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "세종", lat: 36.4801, lon: 127.2890, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "수원", lat: 37.2636, lon: 127.0286, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "제주", lat: 33.4996, lon: 126.5312, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "춘천", lat: 37.8813, lon: 127.7298, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "청주", lat: 36.6424, lon: 127.4890, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "전주", lat: 35.8242, lon: 127.1480, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "포항", lat: 36.0190, lon: 129.3435, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "창원", lat: 35.2280, lon: 128.6811, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "강릉", lat: 37.7519, lon: 128.8761, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "목포", lat: 34.8118, lon: 126.3922, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "여수", lat: 34.7604, lon: 127.6622, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "안동", lat: 36.5684, lon: 128.7294, tz: "Asia/Seoul", group: koreaGroup),
        City(name: "속초", lat: 38.2070, lon: 128.5918, tz: "Asia/Seoul", group: koreaGroup),

        // 아시아
        City(name: "도쿄", lat: 35.6762, lon: 139.6503, tz: "Asia/Tokyo", group: "아시아"),
        City(name: "오사카", lat: 34.6937, lon: 135.5023, tz: "Asia/Tokyo", group: "아시아"),
        City(name: "삿포로", lat: 43.0618, lon: 141.3545, tz: "Asia/Tokyo", group: "아시아"),
        City(name: "베이징", lat: 39.9042, lon: 116.4074, tz: "Asia/Shanghai", group: "아시아"),
        City(name: "상하이", lat: 31.2304, lon: 121.4737, tz: "Asia/Shanghai", group: "아시아"),
        City(name: "홍콩", lat: 22.3193, lon: 114.1694, tz: "Asia/Hong_Kong", group: "아시아"),
        City(name: "타이베이", lat: 25.0330, lon: 121.5654, tz: "Asia/Taipei", group: "아시아"),
        City(name: "싱가포르", lat: 1.3521, lon: 103.8198, tz: "Asia/Singapore", group: "아시아"),
        City(name: "방콕", lat: 13.7563, lon: 100.5018, tz: "Asia/Bangkok", group: "아시아"),
        City(name: "하노이", lat: 21.0278, lon: 105.8342, tz: "Asia/Ho_Chi_Minh", group: "아시아"),
        City(name: "호치민", lat: 10.8231, lon: 106.6297, tz: "Asia/Ho_Chi_Minh", group: "아시아"),
        City(name: "자카르타", lat: -6.2088, lon: 106.8456, tz: "Asia/Jakarta", group: "아시아"),
        City(name: "쿠알라룸푸르", lat: 3.1390, lon: 101.6869, tz: "Asia/Kuala_Lumpur", group: "아시아"),
        City(name: "마닐라", lat: 14.5995, lon: 120.9842, tz: "Asia/Manila", group: "아시아"),
        City(name: "델리", lat: 28.6139, lon: 77.2090, tz: "Asia/Kolkata", group: "아시아"),
        City(name: "뭄바이", lat: 19.0760, lon: 72.8777, tz: "Asia/Kolkata", group: "아시아"),
        City(name: "두바이", lat: 25.2048, lon: 55.2708, tz: "Asia/Dubai", group: "아시아"),
        City(name: "이스탄불", lat: 41.0082, lon: 28.9784, tz: "Europe/Istanbul", group: "아시아"),
        City(name: "텔아비브", lat: 32.0853, lon: 34.7818, tz: "Asia/Jerusalem", group: "아시아"),

        // 유럽
        City(name: "런던", lat: 51.5074, lon: -0.1278, tz: "Europe/London", group: "유럽"),
        City(name: "파리", lat: 48.8566, lon: 2.3522, tz: "Europe/Paris", group: "유럽"),
        City(name: "베를린", lat: 52.5200, lon: 13.4050, tz: "Europe/Berlin", group: "유럽"),
        City(name: "프랑크푸르트", lat: 50.1109, lon: 8.6821, tz: "Europe/Berlin", group: "유럽"),
        City(name: "뮌헨", lat: 48.1351, lon: 11.5820, tz: "Europe/Berlin", group: "유럽"),
        City(name: "로마", lat: 41.9028, lon: 12.4964, tz: "Europe/Rome", group: "유럽"),
        City(name: "밀라노", lat: 45.4642, lon: 9.1900, tz: "Europe/Rome", group: "유럽"),
        City(name: "마드리드", lat: 40.4168, lon: -3.7038, tz: "Europe/Madrid", group: "유럽"),
        City(name: "바르셀로나", lat: 41.3874, lon: 2.1686, tz: "Europe/Madrid", group: "유럽"),
        City(name: "암스테르담", lat: 52.3676, lon: 4.9041, tz: "Europe/Amsterdam", group: "유럽"),
        City(name: "취리히", lat: 47.3769, lon: 8.5417, tz: "Europe/Zurich", group: "유럽"),
        City(name: "빈", lat: 48.2082, lon: 16.3738, tz: "Europe/Vienna", group: "유럽"),
        City(name: "프라하", lat: 50.0755, lon: 14.4378, tz: "Europe/Prague", group: "유럽"),
        City(name: "스톡홀름", lat: 59.3293, lon: 18.0686, tz: "Europe/Stockholm", group: "유럽"),
        City(name: "코펜하겐", lat: 55.6761, lon: 12.5683, tz: "Europe/Copenhagen", group: "유럽"),
        City(name: "더블린", lat: 53.3498, lon: -6.2603, tz: "Europe/Dublin", group: "유럽"),
        City(name: "리스본", lat: 38.7223, lon: -9.1393, tz: "Europe/Lisbon", group: "유럽"),
        City(name: "아테네", lat: 37.9838, lon: 23.7275, tz: "Europe/Athens", group: "유럽"),
        City(name: "모스크바", lat: 55.7558, lon: 37.6173, tz: "Europe/Moscow", group: "유럽"),

        // 북미
        City(name: "뉴욕", lat: 40.7128, lon: -74.0060, tz: "America/New_York", group: "북미"),
        City(name: "워싱턴DC", lat: 38.9072, lon: -77.0369, tz: "America/New_York", group: "북미"),
        City(name: "보스턴", lat: 42.3601, lon: -71.0589, tz: "America/New_York", group: "북미"),
        City(name: "시카고", lat: 41.8781, lon: -87.6298, tz: "America/Chicago", group: "북미"),
        City(name: "덴버", lat: 39.7392, lon: -104.9903, tz: "America/Denver", group: "북미"),
        City(name: "로스앤젤레스", lat: 34.0522, lon: -118.2437, tz: "America/Los_Angeles", group: "북미"),
        City(name: "샌프란시스코", lat: 37.7749, lon: -122.4194, tz: "America/Los_Angeles", group: "북미"),
        City(name: "시애틀", lat: 47.6062, lon: -122.3321, tz: "America/Los_Angeles", group: "북미"),
        City(name: "라스베이거스", lat: 36.1699, lon: -115.1398, tz: "America/Los_Angeles", group: "북미"),
        City(name: "호놀룰루", lat: 21.3069, lon: -157.8583, tz: "Pacific/Honolulu", group: "북미"),
        City(name: "토론토", lat: 43.6532, lon: -79.3832, tz: "America/Toronto", group: "북미"),
        City(name: "밴쿠버", lat: 49.2827, lon: -123.1207, tz: "America/Vancouver", group: "북미"),
        City(name: "멕시코시티", lat: 19.4326, lon: -99.1332, tz: "America/Mexico_City", group: "북미"),

        // 중남미
        City(name: "상파울루", lat: -23.5505, lon: -46.6333, tz: "America/Sao_Paulo", group: "중남미"),
        City(name: "리우데자네이루", lat: -22.9068, lon: -43.1729, tz: "America/Sao_Paulo", group: "중남미"),
        City(name: "부에노스아이레스", lat: -34.6037, lon: -58.3816, tz: "America/Argentina/Buenos_Aires", group: "중남미"),
        City(name: "산티아고", lat: -33.4489, lon: -70.6693, tz: "America/Santiago", group: "중남미"),
        City(name: "리마", lat: -12.0464, lon: -77.0428, tz: "America/Lima", group: "중남미"),
        City(name: "보고타", lat: 4.7110, lon: -74.0721, tz: "America/Bogota", group: "중남미"),

        // 오세아니아
        City(name: "시드니", lat: -33.8688, lon: 151.2093, tz: "Australia/Sydney", group: "오세아니아"),
        City(name: "멜버른", lat: -37.8136, lon: 144.9631, tz: "Australia/Melbourne", group: "오세아니아"),
        City(name: "브리즈번", lat: -27.4698, lon: 153.0251, tz: "Australia/Brisbane", group: "오세아니아"),
        City(name: "퍼스", lat: -31.9523, lon: 115.8613, tz: "Australia/Perth", group: "오세아니아"),
        City(name: "오클랜드", lat: -36.8485, lon: 174.7633, tz: "Pacific/Auckland", group: "오세아니아"),

        // 아프리카·중동
        City(name: "카이로", lat: 30.0444, lon: 31.2357, tz: "Africa/Cairo", group: "아프리카"),
        City(name: "요하네스버그", lat: -26.2041, lon: 28.0473, tz: "Africa/Johannesburg", group: "아프리카"),
        City(name: "나이로비", lat: -1.2921, lon: 36.8219, tz: "Africa/Nairobi", group: "아프리카"),
        City(name: "라고스", lat: 6.5244, lon: 3.3792, tz: "Africa/Lagos", group: "아프리카"),
        City(name: "카사블랑카", lat: 33.5731, lon: -7.5898, tz: "Africa/Casablanca", group: "아프리카"),
    ]

    static var names: [String] { table.map(\.name) }

    static func city(for region: String) -> City? {
        table.first(where: { $0.name == region })
    }

    /// 미등록 지역은 서울 폴백
    static func coords(for region: String) -> (lat: Double, lon: Double) {
        if let c = city(for: region) { return (c.lat, c.lon) }
        return (37.5665, 126.9780)
    }

    /// IANA 타임존 — 미등록 시 서울
    static func tz(for region: String) -> String {
        city(for: region)?.tz ?? "Asia/Seoul"
    }

    /// 한국 도시 여부 (사주 기존 KST/DST 경로 유지 판단용)
    static func isKorea(_ region: String) -> Bool {
        city(for: region)?.group == koreaGroup
    }

    /// 그룹 등장 순서를 유지한 (그룹명, [도시]) — 피커 섹션용
    static var grouped: [(group: String, cities: [City])] {
        var order: [String] = []
        var bucket: [String: [City]] = [:]
        for c in table {
            if bucket[c.group] == nil { order.append(c.group) }
            bucket[c.group, default: []].append(c)
        }
        return order.map { ($0, bucket[$0] ?? []) }
    }
}
