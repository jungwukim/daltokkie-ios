// AI 콘텐츠 항목 정의 — 웹 mobile-{saju,natal,ziwei}-page의 *_CONTENT_SECTIONS 이관

import Foundation

enum AIContentSections {
    static let saju: [AIContentSectionData] = [
        .init(title: "일일 콘텐츠", items: [
            .init(id: "daily-one-liner", emoji: "💬", label: "오늘의 한마디"),
            .init(id: "do-dont", emoji: "✅", label: "DO / DON'T"),
            .init(id: "daily-fortune", emoji: "🔮", label: "오늘의 운세"),
            .init(id: "focus-now", emoji: "🎯", label: "지금 집중할 것"),
            .init(id: "lucky-day", emoji: "📌", label: "택일 (좋은 날)"),
        ]),
        .init(title: "성격 · 재능", items: [
            .init(id: "full-analysis", emoji: "📊", label: "종합 사주풀이"),
            .init(id: "life-mission", emoji: "🧭", label: "나의 사명"),
            .init(id: "talent-discovery", emoji: "💡", label: "재능 발굴"),
            .init(id: "career-aptitude", emoji: "💼", label: "직업 적성"),
            .init(id: "destiny-card", emoji: "🃏", label: "운명 카드"),
            .init(id: "balance-gauge", emoji: "🎮", label: "밸런스 게이지"),
        ]),
        .init(title: "시기 · 운세", items: [
            .init(id: "monthly-fortune", emoji: "📆", label: "이번 달 운세"),
            .init(id: "monthly-energy", emoji: "⚡", label: "이달 핵심 에너지"),
            .init(id: "monthly-detailed", emoji: "📋", label: "월별 상세 (12개월)"),
            .init(id: "fortune-calendar", emoji: "🗓️", label: "운세 달력"),
            .init(id: "yearly-fortune", emoji: "📅", label: "올해 운세"),
            .init(id: "current-worry", emoji: "💭", label: "지금 고민 분석"),
            .init(id: "next-turning-point", emoji: "🔄", label: "다음 전환점"),
            .init(id: "age-guide", emoji: "🗺️", label: "연령대 가이드"),
        ]),
        .init(title: "타이밍 분석", items: [
            .init(id: "timing-money", emoji: "💰", label: "재물 타이밍"),
            .init(id: "timing-love", emoji: "💘", label: "연인 출현 시기"),
            .init(id: "timing-career", emoji: "📈", label: "커리어 피크"),
        ]),
        .init(title: "관계 · 통합", items: [
            .init(id: "love-fortune", emoji: "💕", label: "연애/결혼운"),
            .init(id: "compatibility", emoji: "💑", label: "연인 궁합"),
            .init(id: "cross-report", emoji: "🔗", label: "3엔진 크로스"),
            .init(id: "yearly-cross", emoji: "🌐", label: "3엔진 올해 전망"),
            .init(id: "life-graph", emoji: "📉", label: "인생 그래프"),
        ]),
        .init(title: "프리미엄", items: [
            .init(id: "life-roadmap", emoji: "🛤️", label: "인생 로드맵"),
        ]),
    ]

    static let natal: [AIContentSectionData] = [
        .init(title: "종합 분석", items: [
            .init(id: "natal-full-analysis", emoji: "📊", label: "출생차트 종합"),
            .init(id: "natal-sun-moon", emoji: "☀️", label: "태양 & 달 분석"),
            .init(id: "natal-rising", emoji: "⬆️", label: "상승궁 분석"),
        ]),
        .init(title: "심층 해석", items: [
            .init(id: "natal-houses", emoji: "🏠", label: "12하우스 분석"),
            .init(id: "natal-aspects", emoji: "🔗", label: "어스펙트 분석"),
            .init(id: "natal-element-balance", emoji: "🎨", label: "4원소 밸런스"),
        ]),
        .init(title: "분야별 운세", items: [
            .init(id: "natal-love", emoji: "💕", label: "연애/결혼운"),
            .init(id: "natal-career", emoji: "💼", label: "커리어 분석"),
            .init(id: "natal-transit", emoji: "🌍", label: "현재 트랜짓"),
            .init(id: "natal-monthly", emoji: "📆", label: "이번 달 운세"),
        ]),
    ]

    static let ziwei: [AIContentSectionData] = [
        .init(title: "종합 분석", items: [
            .init(id: "ziwei-full-analysis", emoji: "📊", label: "종합 명반 분석"),
            .init(id: "ziwei-destiny-pattern", emoji: "🧬", label: "운명 패턴"),
            .init(id: "ziwei-palace-analysis", emoji: "🏛️", label: "12궁 상세"),
        ]),
        .init(title: "핵심 해석", items: [
            .init(id: "ziwei-sihua", emoji: "✨", label: "사화 심층 해석"),
            .init(id: "ziwei-daxian", emoji: "🔄", label: "대한 운세"),
            .init(id: "ziwei-liunian", emoji: "📅", label: "올해 유년 운세"),
            .init(id: "ziwei-monthly", emoji: "📆", label: "이번 달 운세"),
        ]),
        .init(title: "분야별 운세", items: [
            .init(id: "ziwei-love", emoji: "💕", label: "연애/부부운"),
            .init(id: "ziwei-career", emoji: "💼", label: "직업/재물운"),
            .init(id: "ziwei-health", emoji: "🏥", label: "건강운"),
        ]),
    ]
}
