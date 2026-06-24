// AI 심층 해석 — 버튼 탭 시 grabber 바텀 시트로 스트리밍 표시 (유료/심층 영역)

import SwiftUI

struct AIInterpretationView: View {
    let title: String
    let start: () -> AsyncThrowingStream<String, Error>

    @State private var text = ""
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var task: Task<Void, Never>?
    @State private var showSheet = false

    var body: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: title)
                Button {
                    openSheet()
                } label: {
                    Label(text.isEmpty ? "달토끼 해석 받기" : "해석 다시 보기", systemImage: "moon.stars.fill")
                        .font(DT.sans(14, .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DT.night)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            AIResultSheet(title: title, text: text, isLoading: isLoading, errorText: errorText,
                          onClose: { showSheet = false }, onRetry: { run() })
        }
        .onDisappear { task?.cancel() }
    }

    private func openSheet() {
        showSheet = true
        if text.isEmpty && !isLoading { run() }
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

/// AI 결과 grabber 바텀 시트 — 드래그 핸들 + 닫기, 부모가 소유한 스트림 상태 표시
struct AIResultSheet: View {
    let title: String
    let text: String
    let isLoading: Bool
    let errorText: String?
    let onClose: () -> Void
    let onRetry: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if errorText != nil {
                        VStack(spacing: 12) {
                            Text("해석을 불러오지 못했어요\n네트워크 연결을 확인해 주세요.")
                                .font(DT.sans(13)).foregroundStyle(DT.inkSoft)
                                .multilineTextAlignment(.center)
                            Button(action: onRetry) {
                                Text("다시 시도").font(DT.sans(13, .semibold)).foregroundStyle(DT.accent)
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.top, 48)
                    } else if text.isEmpty && isLoading {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("달토끼가 해석 중이에요…").font(DT.sans(13)).foregroundStyle(DT.inkSoft)
                        }
                        .frame(maxWidth: .infinity).padding(.top, 48)
                    } else {
                        FormattedAIText(text: text)
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.vertical, 10)
            }
            .background(DT.bg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { CircleCloseButton(action: onClose) }
                if isLoading {
                    ToolbarItem(placement: .topBarLeading) { ProgressView().controlSize(.small) }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large, .medium])
    }
}

/// AI 스트리밍 마크다운을 보기 좋게 렌더 — 제목/문단/목록/인용/구분선 + 인라인 강조(굵게·기울임) 처리,
/// 날것의 마커(#, **, ---, •)와 특수문자는 정리해서 표시
struct FormattedAIText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    // MARK: 블록 모델
    private enum Block {
        case heading(String, level: Int)
        case paragraph(String)
        case bullet(String)
        case numbered(String, String)
        case quote(String)
        case divider
    }

    // MARK: 파싱
    private var blocks: [Block] {
        var result: [Block] = []
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        for raw in normalized.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            // 구분선
            if line.count >= 3, line.allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" }) {
                result.append(.divider); continue
            }
            // 제목 (#, ##, ###…)
            if line.hasPrefix("#") {
                var hashes = 0
                for c in line { if c == "#" { hashes += 1 } else { break } }
                let content = stripInline(String(line.dropFirst(hashes)).trimmingCharacters(in: .whitespaces))
                if !content.isEmpty { result.append(.heading(content, level: min(hashes, 3))); continue }
            }
            // 한 줄 전체가 굵게 → 소제목
            if line.hasPrefix("**"), line.hasSuffix("**"), line.count > 4,
               !line.dropFirst(2).dropLast(2).contains("**") {
                result.append(.heading(stripInline(line), level: 3)); continue
            }
            // 인용
            if line.hasPrefix(">") {
                result.append(.quote(String(line.dropFirst(1)).trimmingCharacters(in: .whitespaces))); continue
            }
            // 글머리표
            if let marker = ["- ", "* ", "+ ", "• ", "· "].first(where: { line.hasPrefix($0) }) {
                result.append(.bullet(String(line.dropFirst(marker.count)))); continue
            }
            // 번호 목록 (1. / 1) )
            if let r = line.range(of: #"^\d+[.)]\s+"#, options: .regularExpression) {
                let num = line[line.startIndex..<line.index(before: r.upperBound)]
                    .trimmingCharacters(in: CharacterSet(charactersIn: ".) "))
                result.append(.numbered(num, String(line[r.upperBound...]))); continue
            }
            result.append(.paragraph(line))
        }
        return result
    }

    /// 인라인 마크다운(**굵게**, *기울임*, `코드`) → AttributedString. 실패 시 마커 제거 후 평문
    private func inlineText(_ s: String) -> Text {
        if let attr = try? AttributedString(
            markdown: s,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attr)
        }
        return Text(stripInline(s))
    }

    private func stripInline(_ s: String) -> String {
        s.replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "*", with: "")
    }

    @ViewBuilder
    private func bodyText(_ s: String, color: Color) -> some View {
        inlineText(s)
            .font(DT.sans(13)).foregroundStyle(color).lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: Block) -> some View {
        switch block {
        case .heading(let t, let level):
            Text(t)
                .font(DT.serif(level <= 1 ? 17 : (level == 2 ? 15 : 14), .bold))
                .foregroundStyle(DT.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
        case .paragraph(let t):
            bodyText(t, color: DT.ink)
        case .bullet(let t):
            HStack(alignment: .top, spacing: 8) {
                Circle().fill(DT.accent).frame(width: 5, height: 5).padding(.top, 6)
                bodyText(t, color: DT.ink)
            }
        case .numbered(let n, let t):
            HStack(alignment: .top, spacing: 8) {
                Text("\(n).").font(DT.sans(13, .bold)).foregroundStyle(DT.accent)
                bodyText(t, color: DT.ink)
            }
        case .quote(let t):
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2).fill(DT.accent.opacity(0.4)).frame(width: 3)
                bodyText(t, color: DT.inkSoft)
            }
            .fixedSize(horizontal: false, vertical: true)
        case .divider:
            Divider().padding(.vertical, 2)
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
