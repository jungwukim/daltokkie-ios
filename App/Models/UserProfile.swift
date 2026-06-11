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
