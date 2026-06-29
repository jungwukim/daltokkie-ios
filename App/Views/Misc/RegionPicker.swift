// 출생 지역 선택 — 세계 주요 도시 검색형 피커 (온보딩·마이 공용)

import SwiftUI

struct RegionPickerSheet: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private struct Section: Identifiable {
        let id: String
        let cities: [RegionCoords.City]
    }

    private var filtered: [Section] {
        let q = query.trimmingCharacters(in: .whitespaces)
        var out: [Section] = []
        for sec in RegionCoords.grouped {
            let hits = q.isEmpty ? sec.cities : sec.cities.filter { $0.name.localizedCaseInsensitiveContains(q) }
            if !hits.isEmpty { out.append(Section(id: sec.group, cities: hits)) }
        }
        return out
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { sec in
                    SwiftUI.Section {
                        ForEach(sec.cities, id: \.name) { c in
                            Button {
                                selection = c.name
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Text(c.name)
                                        .font(DT.sans(15))
                                        .foregroundStyle(DT.ink)
                                    Text(c.country)
                                        .font(DT.sans(11))
                                        .foregroundStyle(DT.inkSoft)
                                    Spacer()
                                    if c.name == selection {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(DT.accent)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(sec.id).font(DT.sans(12, .semibold)).foregroundStyle(DT.inkSoft)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DT.bg)
            .searchable(text: $query, prompt: "도시 이름 검색")
            .navigationTitle("출생 지역")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }.foregroundStyle(DT.accent)
                }
            }
        }
    }
}
