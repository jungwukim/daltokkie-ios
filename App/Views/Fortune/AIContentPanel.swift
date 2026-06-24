// AI 콘텐츠 패널 — 웹 mobile-content-panel 대응
// 톤(MZ/따뜻/전통) 선택 + 섹션별 콘텐츠 버튼, 탭 시 /api/saju/content/{id} 스트리밍

import SwiftUI

struct AIContentItem: Identifiable {
    let id: String
    let emoji: String
    let label: String
}
struct AIContentSectionData: Identifiable {
    let id = UUID()
    let title: String
    let items: [AIContentItem]
}

struct AIContentPanel: View {
    let title: String
    let sections: [AIContentSectionData]
    /// (contentId, tone) → 스트림
    let makeStream: (String, String) -> AsyncThrowingStream<String, Error>

    @State private var tone = "mz"
    @State private var activeId: String?
    @State private var text = ""
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var task: Task<Void, Never>?
    @State private var showSheet = false
    @State private var sheetTitle = ""

    private let tones: [(String, String)] = [("mz", "MZ 감성"), ("warm", "따뜻한 상담사"), ("classic", "전통 역술가")]
    private let cols = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: title)

                // 톤 선택
                Picker("", selection: $tone) {
                    ForEach(tones, id: \.0) { Text($0.1).tag($0.0) }
                }
                .pickerStyle(.segmented)

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.title).font(DT.sans(12, .bold)).foregroundStyle(DT.inkSoft)
                        LazyVGrid(columns: cols, spacing: 8) {
                            ForEach(section.items) { item in
                                Button {
                                    sheetTitle = "\(item.emoji) \(item.label)"
                                    showSheet = true
                                    run(item.id)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(item.emoji).font(.system(size: 13))
                                        Text(item.label).font(DT.sans(11, .medium)).lineLimit(1).minimumScaleFactor(0.7)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9).padding(.horizontal, 6)
                                    .background(activeId == item.id ? DT.accent : DT.bg)
                                    .foregroundStyle(activeId == item.id ? .white : DT.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

            }
        }
        .sheet(isPresented: $showSheet) {
            AIResultSheet(title: sheetTitle, text: text, isLoading: isLoading, errorText: errorText,
                          onClose: { showSheet = false },
                          onRetry: { if let id = activeId { run(id) } })
        }
        .onDisappear { task?.cancel() }
    }

    private func run(_ id: String) {
        task?.cancel()
        activeId = id; text = ""; errorText = nil; isLoading = true
        task = Task {
            do {
                for try await chunk in makeStream(id, tone) { text += chunk }
            } catch {
                if !Task.isCancelled { errorText = "\(error)" }
            }
            isLoading = false
        }
    }
}
