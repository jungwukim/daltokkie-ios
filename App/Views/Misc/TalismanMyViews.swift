// 부적함 + 마이 탭

import SwiftUI

struct TalismanView: View {
    private let characters: [(asset: String, name: String, blessing: String)] = [
        ("char-wolya", "월야", "달빛의 가호 — 마음의 평온"),
        ("char-baekhwa", "백화", "흰 꽃의 가호 — 새로운 시작"),
        ("char-yeonmong", "연몽", "꿈결의 가호 — 좋은 인연"),
        ("char-yunsan", "윤산", "산의 가호 — 굳건한 의지"),
        ("char-hongmae", "홍매", "매화의 가호 — 재물과 결실"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("부적함")
                    .font(DT.serif(20, .bold))
                    .foregroundStyle(DT.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)

                ForEach(characters, id: \.asset) { item in
                    CraftCard {
                        HStack(spacing: 14) {
                            Image(item.asset)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 84, height: 84)
                                .background(Color(hex: 0xF3ECDD))   // 아트 크림 톤 타일 — 라이트/다크 공통 프레임
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DT.line, lineWidth: 1))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.name)
                                    .font(DT.serif(17, .bold))
                                    .foregroundStyle(DT.ink)
                                Text(item.blessing)
                                    .font(DT.sans(12))
                                    .foregroundStyle(DT.inkSoft)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, DT.pagePadding)
            .padding(.bottom, 24)
        }
        .background(DT.bg)
    }
}

struct MyView: View {
    @EnvironmentObject var appState: AppState
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("마이")
                    .font(DT.serif(20, .bold))
                    .foregroundStyle(DT.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)

                if let p = appState.profile {
                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: p.name.isEmpty ? "내 정보" : "\(p.name)님의 정보")
                            infoRow("생년월일", "\(p.calendar == "lunar" ? "음력 " : "")\(p.year)년 \(p.month)월 \(p.day)일\(p.isLeapMonth ? " (윤달)" : "")")
                            infoRow("태어난 시간", p.hour.map { String(format: "%02d:%02d", $0, p.minute) } ?? "모름")
                            infoRow("성별", p.gender == "male" ? "남성" : "여성")
                            regionRow(p.region)
                            if let saju = appState.ensureSaju() {
                                infoRow("사주", saju.displayHanja)
                                infoRow("일간", "\(saju.dayMaster.hanja) — \(saju.dayMasterProfile?.image ?? "")")
                                infoRow("띠", "\(animalKo(saju.animal))띠")
                            }
                        }
                    }
                }

                CraftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "설정")
                        Button(role: .destructive) {
                            confirmReset = true
                        } label: {
                            Label("생년월일 다시 입력하기", systemImage: "arrow.counterclockwise")
                                .font(DT.sans(14))
                        }
                    }
                }

                Text("모든 운세 계산은 기기 안에서 이뤄집니다.\n생년월일 정보는 이 기기에만 저장돼요.")
                    .font(DT.sans(11))
                    .foregroundStyle(DT.inkSoft)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.horizontal, DT.pagePadding)
            .padding(.bottom, 24)
        }
        .background(DT.bg)
        .confirmationDialog("저장된 생년월일을 지우고 다시 입력할까요?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("다시 입력", role: .destructive) {
                UserProfile.clear()
                appState.profile = nil
            }
            Button("취소", role: .cancel) {}
        }
    }

    private func animalKo(_ en: String) -> String {
        ["Rat": "쥐", "Ox": "소", "Tiger": "호랑이", "Rabbit": "토끼", "Dragon": "용", "Snake": "뱀",
         "Horse": "말", "Goat": "양", "Monkey": "원숭이", "Rooster": "닭", "Dog": "개", "Pig": "돼지"][en] ?? en
    }

    /// 출생 지역 — 점성술 ASC/MC 좌표 보정용 (선택 시 즉시 재계산)
    private func regionRow(_ region: String) -> some View {
        HStack {
            Text("출생 지역")
                .font(DT.sans(12)).foregroundStyle(DT.inkSoft)
                .frame(width: 88, alignment: .leading)
            Menu {
                ForEach(RegionCoords.names, id: \.self) { name in
                    Button(name) { setRegion(name) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(region).font(DT.sans(13, .medium)).foregroundStyle(DT.accent)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundStyle(DT.inkSoft)
                }
            }
            Spacer()
        }
    }

    private func setRegion(_ name: String) {
        guard var p = appState.profile, p.region != name else { return }
        p.region = name
        appState.profile = p   // didSet → 저장 + 캐시 무효화(재계산)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(DT.sans(12))
                .foregroundStyle(DT.inkSoft)
                .frame(width: 88, alignment: .leading)
            Text(value)
                .font(DT.sans(13, .medium))
                .foregroundStyle(DT.ink)
            Spacer()
        }
    }
}
