// AI 심층 해석 카드 — 프록시 스트리밍 표시 (유료/심층 영역)

import SwiftUI

struct AIInterpretationView: View {
    let title: String
    let start: () -> AsyncThrowingStream<String, Error>

    @State private var text = ""
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var task: Task<Void, Never>?

    var body: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionTitle(text: title)
                    Spacer()
                    if isLoading { ProgressView().controlSize(.small) }
                }

                if let errorText {
                    Text("해석을 불러오지 못했어요 (\(errorText))\n네트워크 연결을 확인해 주세요.")
                        .font(DT.sans(12))
                        .foregroundStyle(DT.inkSoft)
                } else if text.isEmpty && !isLoading {
                    Button {
                        run()
                    } label: {
                        Label("달토끼 AI 해석 받기", systemImage: "moon.stars.fill")
                            .font(DT.sans(14, .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(DT.night)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    Text(text)
                        .font(DT.sans(14))
                        .foregroundStyle(DT.ink)
                        .lineSpacing(5)
                        .textSelection(.enabled)
                }
            }
        }
        .onDisappear { task?.cancel() }
    }

    private func run() {
        isLoading = true
        errorText = nil
        text = ""
        task = Task {
            do {
                for try await chunk in start() {
                    text += chunk
                }
            } catch {
                if !Task.isCancelled { errorText = "\(error)" }
            }
            isLoading = false
        }
    }
}

/// 상세 페이지 공용 행
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(DT.sans(12))
                .foregroundStyle(DT.inkSoft)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(DT.sans(13, .medium))
                .foregroundStyle(DT.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// 사주 4기둥 한자 그리드 (공용)
import SajuKit

struct PillarGrid: View {
    let result: FortuneTellerResult
    var onDark: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            pillarColumn("시주", result.pillars.hour)
            pillarColumn("일주", result.pillars.day)
            pillarColumn("월주", result.pillars.month)
            pillarColumn("년주", result.pillars.year)
        }
    }

    private var titleColor: Color { onDark ? .white.opacity(0.6) : DT.inkSoft }
    private var koreanColor: Color { onDark ? .white.opacity(0.6) : DT.inkSoft }
    private var cellBg: Color { onDark ? .white.opacity(0.07) : DT.bg }

    private func pillarColumn(_ title: String, _ pillar: UIPillar?) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(DT.sans(11))
                .foregroundStyle(titleColor)
            if let p = pillar {
                Text(p.stem.hanja)
                    .font(DT.serif(30, .bold))
                    .foregroundStyle(onDark ? sajuElementColor(p.stem.element) : DT.ink)
                Text(p.branch.hanja)
                    .font(DT.serif(30, .bold))
                    .foregroundStyle(onDark ? sajuElementColor(p.branch.element) : DT.ink)
                Text("\(p.stem.korean)\(p.branch.korean)")
                    .font(DT.sans(11))
                    .foregroundStyle(koreanColor)
            } else {
                Text("?")
                    .font(DT.serif(30, .bold))
                    .foregroundStyle((onDark ? Color.white : DT.inkSoft).opacity(0.5))
                Text("미상")
                    .font(DT.sans(11))
                    .foregroundStyle(koreanColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cellBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
