// 자미두수 명반 계산 (saju-api lib/ziwei/ziwei-engine.ts 포팅)
// 음력 변환은 LunarKit(LunarConverter — lunar-javascript 호환 테이블) 사용.

import Foundation
import LunarKit

public enum ZiweiEngine {

    // MARK: - 간지 인덱스 유틸

    private static func zhiIndex(_ zhi: String) -> Int { ZC.diZhi.firstIndex(of: zhi) ?? -1 }
    private static func ganIndex(_ gan: String) -> Int { ZC.tianGan.firstIndex(of: gan) ?? -1 }
    private static func zhiAt(_ index: Int) -> String { ZC.diZhi[((index % 12) + 12) % 12] }
    private static func ganAt(_ index: Int) -> String { ZC.tianGan[((index % 10) + 10) % 10] }

    /// 시(時) → 시진 인덱스. 23시와 0시는 子시(0).
    private static func hourZhiIndex(_ hour: Int) -> Int {
        if hour == 23 || hour == 0 { return 0 }
        return ((hour + 1) / 2) % 12
    }

    private static func yearGanZhi(_ lunarYear: Int) -> (gan: String, zhi: String) {
        let ganIdx = ((lunarYear - 4) % 10 + 10) % 10
        let zhiIdx = ((lunarYear - 4) % 12 + 12) % 12
        return (ganAt(ganIdx), zhiAt(zhiIdx))
    }

    // MARK: - 명궁/신궁/오행국

    private static func mingGong(lunarMonth: Int, hour: Int) -> String {
        let monthPalaceIdx = (2 + lunarMonth - 1) % 12
        let hourIdx = hourZhiIndex(hour)
        return zhiAt(((monthPalaceIdx - hourIdx) % 12 + 12) % 12)
    }

    private static func shenGong(lunarMonth: Int, hour: Int) -> String {
        let monthPalaceIdx = (2 + lunarMonth - 1) % 12
        return zhiAt((monthPalaceIdx + hourZhiIndex(hour)) % 12)
    }

    private static func palaceGan(yearGan: String, zhi: String) -> String {
        let startGan = ZC.wuHuDunGan[yearGan]!
        let offset = ((zhiIndex(zhi) - zhiIndex("寅")) % 12 + 12) % 12
        return ganAt(ganIndex(startGan) + offset)
    }

    private static func wuXingJu(palaceGan: String, palaceZhi: String) -> WuXingJu {
        let key = "\(palaceGan),\(palaceZhi)"
        if let element = ZC.nayinTable[key], let ju = ZC.wuXingJuMap[element] {
            return ju
        }
        return ZC.wuXingJuMap["water"]!
    }

    // MARK: - 별 배치

    private static func ziweiPosition(lunarDay: Int, juNumber: Int) -> String {
        let quotient = lunarDay / juNumber
        let remainder = lunarDay % juNumber

        var position: Int
        if remainder == 0 {
            position = quotient
        } else {
            let add = juNumber - remainder
            position = quotient + 1
            if add % 2 == 1 {
                position -= add
            } else {
                position += add
            }
        }
        while position > 12 { position -= 12 }
        while position < 1 { position += 12 }
        return zhiAt((position - 1 + 2) % 12)
    }

    private static func tianfuPosition(ziweiZhi: String) -> String {
        let ziweiPos = ((zhiIndex(ziweiZhi) - 2) % 12 + 12) % 12 + 1
        var tianfuPos = 14 - ziweiPos
        if tianfuPos > 12 { tianfuPos -= 12 }
        return zhiAt((tianfuPos - 1 + 2) % 12)
    }

    /// 14주성 배치 — 반환 순서가 픽스처 stars 배열 순서를 결정하므로 배열 유지
    private static func mainStars(ziweiZhi: String, tianfuZhi: String) -> [(name: String, zhi: String)] {
        let ziweiIdx = zhiIndex(ziweiZhi)
        let tianfuIdx = zhiIndex(tianfuZhi)
        var result: [(String, String)] = []
        for (star, offset) in ZC.ziweiSeriesOffsets {
            result.append((star, zhiAt(ziweiIdx + offset)))
        }
        for (star, offset) in ZC.tianfuSeriesOffsets {
            result.append((star, zhiAt(tianfuIdx + offset)))
        }
        return result
    }

    /// 보성 배치 — TS placeAuxStars의 삽입 순서 그대로
    private static func auxStars(yearGan: String, yearZhi: String, lunarMonth: Int, hour: Int) -> [(name: String, zhi: String)] {
        let hourIdx = hourZhiIndex(hour)
        var result: [(String, String)] = []

        result.append(("左輔", zhiAt(zhiIndex("辰") + lunarMonth - 1)))
        result.append(("右弼", zhiAt(zhiIndex("戌") - (lunarMonth - 1))))

        result.append(("文昌", zhiAt(zhiIndex("戌") - hourIdx)))
        result.append(("文曲", zhiAt(zhiIndex("辰") + hourIdx)))
        result.append(("地空", zhiAt(zhiIndex("亥") - hourIdx)))
        result.append(("地劫", zhiAt(zhiIndex("亥") + hourIdx)))

        let luCun = ZC.luCunTable[yearGan]!
        result.append(("祿存", luCun))
        let luCunIdx = zhiIndex(luCun)
        result.append(("擎羊", zhiAt(luCunIdx + 1)))
        result.append(("陀羅", zhiAt(luCunIdx - 1)))

        let kuiYue = ZC.kuiYueTable[yearGan]!
        result.append(("天魁", kuiYue[0]))
        result.append(("天鉞", kuiYue[1]))

        result.append(("火星", zhiAt(zhiIndex(ZC.huoXingStart[yearZhi]!) + hourIdx)))
        result.append(("鈴星", zhiAt(zhiIndex(ZC.lingXingStart[yearZhi]!) + hourIdx)))

        result.append(("天馬", ZC.tianMaTable[yearZhi]!))

        return result
    }

    private static func siHua(yearGan: String) -> [String: String] {
        let stars = ZC.siHuaTable[yearGan]!
        return [stars[0]: "化祿", stars[1]: "化權", stars[2]: "化科", stars[3]: "化忌"]
    }

    private static func brightness(star: String, zhi: String) -> String {
        ZC.brightnessTable[star]?[zhi] ?? ""
    }

    // MARK: - 명반 생성

    public static func createChart(
        year: Int, month: Int, day: Int,
        hour: Int, minute: Int, isMale: Bool
    ) throws -> ZiweiChart {
        let lunar = try LunarConverter.solarToLunar(year: year, month: month, day: day)
        let (yearGan, yearZhi) = yearGanZhi(lunar.year)
        let mingGongZhi = mingGong(lunarMonth: lunar.month, hour: hour)
        let shenGongZhi = shenGong(lunarMonth: lunar.month, hour: hour)
        let mingGongGan = palaceGan(yearGan: yearGan, zhi: mingGongZhi)
        let ju = wuXingJu(palaceGan: mingGongGan, palaceZhi: mingGongZhi)
        let ziweiZhi = ziweiPosition(lunarDay: lunar.day, juNumber: ju.number)
        let tianfuZhi = tianfuPosition(ziweiZhi: ziweiZhi)
        let mains = mainStars(ziweiZhi: ziweiZhi, tianfuZhi: tianfuZhi)
        let auxes = auxStars(yearGan: yearGan, yearZhi: yearZhi, lunarMonth: lunar.month, hour: hour)
        let hua = siHua(yearGan: yearGan)

        var palaces: [String: ZiweiPalace] = [:]
        let mingIdx = zhiIndex(mingGongZhi)

        for (i, palaceName) in ZC.palaceNames.enumerated() {
            let zhi = zhiAt(mingIdx - i)
            let gan = palaceGan(yearGan: yearGan, zhi: zhi)

            var stars: [ZiweiStar] = []
            for (starName, starZhi) in mains where starZhi == zhi {
                stars.append(ZiweiStar(name: starName, brightness: brightness(star: starName, zhi: zhi), siHua: hua[starName] ?? ""))
            }
            for (starName, starZhi) in auxes where starZhi == zhi {
                stars.append(ZiweiStar(name: starName, brightness: "", siHua: hua[starName] ?? ""))
            }

            palaces[palaceName] = ZiweiPalace(
                name: palaceName, zhi: zhi, gan: gan, ganZhi: "\(gan)\(zhi)",
                stars: stars, isShenGong: zhi == shenGongZhi
            )
        }

        return ZiweiChart(
            solarYear: year, solarMonth: month, solarDay: day,
            hour: hour, minute: minute, isMale: isMale,
            lunarYear: lunar.year, lunarMonth: lunar.month, lunarDay: lunar.day,
            isLeapMonth: lunar.isLeapMonth,
            yearGan: yearGan, yearZhi: yearZhi,
            mingGongZhi: mingGongZhi, shenGongZhi: shenGongZhi,
            wuXingJu: ju, palaces: palaces,
            daXianStartAge: ju.number
        )
    }

    // MARK: - 유년(流年)

    private static func palaceByZhi(_ chart: ZiweiChart, _ zhi: String) -> ZiweiPalace? {
        chart.palaces.values.first { $0.zhi == zhi }
    }

    private static func currentDaxian(_ chart: ZiweiChart, year: Int) -> (name: String, start: Int, end: Int) {
        let age = year - chart.solarYear + 1
        let startAge = chart.daXianStartAge
        let mingIdx = zhiIndex(chart.mingGongZhi)

        let isYangGan = ganIndex(chart.yearGan) % 2 == 0
        let direction = (isYangGan && chart.isMale) || (!isYangGan && !chart.isMale) ? 1 : -1

        // 음수 나눗셈: TS Math.floor와 동일하게 floor 처리
        var daxianNum = Int(floor(Double(age - startAge) / 10.0))
        if daxianNum < 0 { daxianNum = 0 }
        if daxianNum > 11 { daxianNum = 11 }

        let daxianStart = startAge + daxianNum * 10
        let daxianEnd = daxianStart + 9

        let palaceIdx = ((mingIdx + daxianNum * direction) % 12 + 12) % 12
        let palace = palaceByZhi(chart, zhiAt(palaceIdx))
        return (palace?.name ?? "?", daxianStart, daxianEnd)
    }

    public static func calculateLiunian(chart: ZiweiChart, year: Int) -> LiuNianInfo {
        let (lnGan, lnZhi) = yearGanZhi(year)
        let lnMingZhi = lnZhi

        let natalPalaceName = palaceByZhi(chart, lnMingZhi)?.name ?? "?"
        let lnSiHua = siHua(yearGan: lnGan)

        var siHuaPalaces: [String: String] = [:]
        for (starName, huaType) in lnSiHua {
            // 별은 정확히 하나의 궁에만 배치되므로 순서 무관
            for palace in chart.palaces.values {
                if palace.stars.contains(where: { $0.name == starName }) {
                    siHuaPalaces[huaType] = palace.name
                    break
                }
            }
        }

        var lnPalaces: [String: String] = [:]
        let lnMingIdx = zhiIndex(lnMingZhi)
        for (i, name) in ZC.palaceNames.enumerated() {
            lnPalaces[name] = zhiAt(lnMingIdx - i)
        }

        var liuyue: [LiuYueInfo] = []
        for m in 1...12 {
            let lyMingZhi = zhiAt((lnMingIdx + (m - 1)) % 12)
            liuyue.append(LiuYueInfo(
                month: m,
                mingGongZhi: lyMingZhi,
                natalPalaceName: palaceByZhi(chart, lyMingZhi)?.name ?? "?"
            ))
        }

        let daxian = currentDaxian(chart, year: year)

        return LiuNianInfo(
            year: year, gan: lnGan, zhi: lnZhi,
            mingGongZhi: lnMingZhi, natalPalaceAtMing: natalPalaceName,
            siHua: lnSiHua, siHuaPalaces: siHuaPalaces, palaces: lnPalaces,
            liuyue: liuyue,
            daxianPalaceName: daxian.name, daxianAgeStart: daxian.start, daxianAgeEnd: daxian.end
        )
    }

    // MARK: - 대한(大限)

    public static func daxianList(chart: ZiweiChart) -> [DaxianInfo] {
        let startAge = chart.daXianStartAge
        let mingIdx = zhiIndex(chart.mingGongZhi)
        let isYangGan = ganIndex(chart.yearGan) % 2 == 0
        let direction = (isYangGan && chart.isMale) || (!isYangGan && !chart.isMale) ? 1 : -1

        var result: [DaxianInfo] = []
        for i in 0..<12 {
            let palaceIdx = ((mingIdx + i * direction) % 12 + 12) % 12
            guard let palace = palaceByZhi(chart, zhiAt(palaceIdx)) else { continue }
            result.append(DaxianInfo(
                ageStart: startAge + i * 10,
                ageEnd: startAge + i * 10 + 9,
                palaceName: palace.name,
                ganZhi: palace.ganZhi,
                mainStars: palace.stars.filter { ZC.mainStarNames.contains($0.name) }.map { $0.name }
            ))
        }
        return result
    }
}
