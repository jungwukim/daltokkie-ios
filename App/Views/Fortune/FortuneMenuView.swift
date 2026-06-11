// 운세 메뉴 — 사주팔자/점성술/자미두수/궁합 4카드 (웹 fortune-menu.tsx 대응)

import SwiftUI

struct FortuneMenuView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("달토끼 운세")
                        .font(DT.serif(20, .bold))
                        .foregroundStyle(DT.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                        NavigationLink(destination: SajuDetailView()) {
                            menuCard("사주팔자", "타고난 운명의 설계도", "sun.and.horizon.fill")
                        }
                        NavigationLink(destination: NatalDetailView()) {
                            menuCard("점성술", "별이 그리는 당신의 지도", "sparkles")
                        }
                        NavigationLink(destination: ZiweiDetailView()) {
                            menuCard("자미두수", "동양 별자리 명반", "star.circle.fill")
                        }
                        NavigationLink(destination: CompatibilityView()) {
                            menuCard("궁합", "두 사람의 인연", "heart.circle.fill")
                        }
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.bottom, 24)
            }
            .background(DT.bg)
        }
        .tint(DT.ink)
    }

    private func menuCard(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(DT.accent)
            Text(title)
                .font(DT.serif(17, .bold))
                .foregroundStyle(DT.ink)
            Text(subtitle)
                .font(DT.sans(11))
                .foregroundStyle(DT.inkSoft)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: DT.radius))
        .overlay(RoundedRectangle(cornerRadius: DT.radius).stroke(DT.line, lineWidth: 1))
    }
}
