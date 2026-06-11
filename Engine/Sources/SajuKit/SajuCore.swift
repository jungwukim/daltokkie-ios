// 사주팔자 코어 — hoshin saju.ts(연/월/일/시주) + utils/date.ts(시간 보정) 포팅
//
// ⚠️ 시각 해석 규칙: hoshin은 모든 날짜 성분 추출을 Asia/Seoul 기준으로 수행한다
// (원본은 일부 서버 로컬 타임존 의존이 있으나 픽스처 생성 환경이 Asia/Seoul이므로
//  Seoul로 통일 — 골든 픽스처와의 일치가 정확성 기준).

import Foundation
import LunarKit

public enum SajuCore {
    static let seoul = TimeZone(identifier: "Asia/Seoul")!

    static var seoulCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = seoul
        return cal
    }

    // MARK: - 절기 (근사 테이블 — hoshin getCurrentSolarTerm)

    /// 24절기 순서 (입춘=0 … 대한=23)
    static let termOrder = [
        "입춘", "우수", "경칩", "춘분", "청명", "곡우", "입하", "소만",
        "망종", "하지", "소서", "대서", "입추", "처서", "백로", "추분",
        "한로", "상강", "입동", "소설", "대설", "동지", "소한", "대한",
    ]

    /// 근사 시작일 [month, day] (hoshin SOLAR_TERM_APPROXIMATE_DATES)
    static let approxDates: [String: (Int, Int)] = [
        "입춘": (2, 4), "우수": (2, 19), "경칩": (3, 6), "춘분": (3, 21),
        "청명": (4, 5), "곡우": (4, 20), "입하": (5, 6), "소만": (5, 21),
        "망종": (6, 6), "하지": (6, 21), "소서": (7, 7), "대서": (7, 23),
        "입추": (8, 8), "처서": (8, 23), "백로": (9, 8), "추분": (9, 23),
        "한로": (10, 8), "상강": (10, 23), "입동": (11, 7), "소설": (11, 22),
        "대설": (12, 7), "동지": (12, 22), "소한": (1, 6), "대한": (1, 20),
    ]

    /// hoshin getCurrentSolarTerm — 근사 (±1일). 월주/연주/지장간 월령이 이 함수를 쓴다.
    static func currentSolarTerm(month: Int, day: Int) -> String {
        let dateNum = month * 100 + day

        let dongji = approxDates["동지"]!
        if month == 12 && day >= dongji.1 { return "동지" }

        let sohan = approxDates["소한"]!
        let daehan = approxDates["대한"]!
        let ipchun = approxDates["입춘"]!
        if month == 1 {
            if day < sohan.1 { return "동지" }
            if day < daehan.1 { return "소한" }
            return "대한"
        }
        if month == 2 && day < ipchun.1 { return "대한" }

        for i in 0..<termOrder.count {
            let current = termOrder[i]
            if current == "소한" || current == "대한" { continue }
            let next = termOrder[(i + 1) % termOrder.count]
            let (cm, cd) = approxDates[current]!
            let (nm, nd) = approxDates[next]!
            let curNum = cm * 100 + cd
            let nextNum = nm * 100 + nd
            if dateNum >= curNum && (nextNum > curNum ? dateNum < nextNum : true) {
                return current
            }
        }
        return "입춘"
    }

    /// 절기 → 월 인덱스 (입춘·우수=0 … 2개 절기당 1개월)
    static func solarTermMonthIndex(_ term: String) -> Int {
        let idx = termOrder.firstIndex(of: term) ?? 0
        return idx / 2
    }

    // MARK: - 시간 보정 (utils/date.ts)

    /// 출생 벽시계(Asia/Seoul, 서머타임 반영)를 UTC 시각으로 (parseBirthDateTimeKorea)
    static func parseSeoulWallClock(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        guard let date = seoulCalendar.date(from: comps) else {
            throw SajuError.invalidInput("\(year)-\(month)-\(day) \(hour):\(minute)")
        }
        return date
    }

    /// 출생 시각 + 출생지 경도 보정 (getAdjustedBirthInstantForSaju — hoshin은 항상 서울 -32분)
    static func adjustedBirthInstant(
        year: Int, month: Int, day: Int, hour: Int, minute: Int, longitudeOffsetMin: Int
    ) throws -> Date {
        let wall = try parseSeoulWallClock(year: year, month: month, day: day, hour: hour, minute: minute)
        return wall.addingTimeInterval(Double(longitudeOffsetMin) * 60)
    }

    // MARK: - 기둥 계산 (hoshin saju.ts)

    struct SeoulComponents {
        let year: Int
        let month: Int
        let day: Int
        let hour: Int
    }

    static func seoulComponents(of date: Date) -> SeoulComponents {
        let c = seoulCalendar.dateComponents([.year, .month, .day, .hour], from: date)
        return SeoulComponents(year: c.year!, month: c.month!, day: c.day!, hour: c.hour!)
    }

    static func calculateYearPillar(_ comps: SeoulComponents) -> FtPillar {
        let solarTerm = currentSolarTerm(month: comps.month, day: comps.day)
        var sajuYear = comps.year
        if comps.month <= 2 && (solarTerm == "동지" || solarTerm == "소한" || solarTerm == "대한") {
            sajuYear = comps.year - 1
        }
        let stemIndex = (sajuYear - 4) % 10
        let branchIndex = (sajuYear - 4) % 12
        return makePillar(stemIndex: stemIndex, branchIndex: branchIndex)
    }

    static func calculateMonthPillar(_ comps: SeoulComponents, yearPillar: FtPillar) -> FtPillar {
        let solarTerm = currentSolarTerm(month: comps.month, day: comps.day)
        let monthIndex = solarTermMonthIndex(solarTerm)
        let branchIndex = (monthIndex + 2) % 12

        let yearStemIndex = SajuTables.stemIndex(korean: yearPillar.stem)
        let monthStemStart: Int
        switch yearStemIndex {
        case 0, 5: monthStemStart = 2   // 갑·기년: 병인월
        case 1, 6: monthStemStart = 4   // 을·경년: 무인월
        case 2, 7: monthStemStart = 6   // 병·신년: 경인월
        case 3, 8: monthStemStart = 8   // 정·임년: 임인월
        default: monthStemStart = 0     // 무·계년: 갑인월
        }

        let monthOffset = branchIndex >= 2 ? branchIndex - 2 : branchIndex + 10
        let stemIndex = (monthStemStart + monthOffset) % 10
        return makePillar(stemIndex: stemIndex, branchIndex: branchIndex)
    }

    /// 일주 — 기준일 1900-01-01 = 갑술일. Seoul 달력일 기준 일수 차.
    static func calculateDayPillar(_ comps: SeoulComponents) -> FtPillar {
        let diffDays = JulianDay.jdn(comps.year, comps.month, comps.day) - JulianDay.jdn(1900, 1, 1)
        let stemIndex = ((0 + diffDays) % 10 + 10) % 10
        let branchIndex = ((10 + diffDays) % 12 + 12) % 12
        return makePillar(stemIndex: stemIndex, branchIndex: branchIndex)
    }

    static func calculateHourPillar(_ comps: SeoulComponents, dayPillar: FtPillar) -> FtPillar {
        let hours = comps.hour
        let branchIndex: Int
        if hours >= 23 || hours < 1 {
            branchIndex = 0
        } else {
            branchIndex = (hours + 1) / 2
        }
        let dayStemIndex = SajuTables.stemIndex(korean: dayPillar.stem)
        let stemIndex = (dayStemIndex * 2 + branchIndex) % 10
        return makePillar(stemIndex: stemIndex, branchIndex: branchIndex)
    }

    static func makePillar(stemIndex: Int, branchIndex: Int) -> FtPillar {
        let stem = SajuTables.stem(at: stemIndex)
        let branch = SajuTables.branch(at: branchIndex)
        return FtPillar(
            stem: stem.korean, branch: branch.korean,
            stemElement: stem.element, branchElement: branch.element,
            yinYang: stem.yinYang
        )
    }

    // MARK: - hoshin calculateSaju 등가 (양력 입력 전제 — 음력 변환은 호출측)

    /// birthDate/Time은 이미 보정된 값 (KDT/진태양시는 SajuCalculator가 적용)
    public static func calculateRaw(
        solarYear: Int, solarMonth: Int, solarDay: Int,
        hour: Int, minute: Int, gender: String
    ) throws -> SajuRawData {
        // hoshin은 항상 서울 경도 보정 -32분 (ftCalculateSaju가 birthCity="서울" 고정 전달)
        let adjusted = try adjustedBirthInstant(
            year: solarYear, month: solarMonth, day: solarDay,
            hour: hour, minute: minute, longitudeOffsetMin: -32
        )
        let comps = seoulComponents(of: adjusted)

        let yearPillar = calculateYearPillar(comps)
        let monthPillar = calculateMonthPillar(comps, yearPillar: yearPillar)
        let dayPillar = calculateDayPillar(comps)
        let hourPillar = calculateHourPillar(comps, dayPillar: dayPillar)

        var wuxingCount: [String: Int] = ["목": 0, "화": 0, "토": 0, "금": 0, "수": 0]
        for pillar in [yearPillar, monthPillar, dayPillar, hourPillar] {
            wuxingCount[pillar.stemElement]! += 1
            wuxingCount[pillar.branchElement]! += 1
        }

        let term = currentSolarTerm(month: comps.month, day: comps.day)
        let monthIndex = solarTermMonthIndex(term)

        let birthDateStr = String(format: "%04d-%02d-%02d", solarYear, solarMonth, solarDay)

        return SajuRawData(
            year: yearPillar, month: monthPillar, day: dayPillar, hour: hourPillar,
            wuxingCount: wuxingCount, gender: gender,
            birthDate: birthDateStr, adjustedInstant: adjusted, monthIndex: monthIndex
        )
    }
}
