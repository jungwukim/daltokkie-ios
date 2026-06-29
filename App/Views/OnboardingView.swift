// 온보딩 — 생년월일시 입력 (웹 birth-info-form 대응, 영구 저장)

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState

    @State private var name = ""
    @State private var year = 1995
    @State private var month = 6
    @State private var day = 15
    @State private var knowsTime = true
    @State private var hour = 12
    @State private var minute = 0
    @State private var gender = "female"
    @State private var calendarType = "solar"
    @State private var isLeapMonth = false
    @State private var region = "서울"
    @State private var showRegionPicker = false

    private let years = Array(1920...2025).reversed()

    var body: some View {
        ZStack {
            DT.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Image("moon-rabbit")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 170)
                        Text("달토끼가 당신의 운세를 준비할게요")
                            .font(DT.serif(20, .bold))
                            .foregroundStyle(DT.ink)
                        Text("생년월일시를 알려주시면 사주·점성술·자미두수를\n모두 기기 안에서 계산해 드려요")
                            .font(DT.sans(13))
                            .foregroundStyle(DT.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)

                    CraftCard {
                        VStack(alignment: .leading, spacing: 16) {
                            field("이름 (선택)") {
                                TextField("달토끼", text: $name)
                                    .textFieldStyle(.plain)
                                    .font(DT.sans(15))
                            }

                            field("성별") {
                                Picker("", selection: $gender) {
                                    Text("여성").tag("female")
                                    Text("남성").tag("male")
                                }
                                .pickerStyle(.segmented)
                            }

                            field("양력 / 음력") {
                                Picker("", selection: $calendarType) {
                                    Text("양력").tag("solar")
                                    Text("음력").tag("lunar")
                                }
                                .pickerStyle(.segmented)
                            }

                            if calendarType == "lunar" {
                                Toggle("윤달", isOn: $isLeapMonth)
                                    .font(DT.sans(14))
                            }

                            field("생년월일") {
                                HStack {
                                    Picker("년", selection: $year) {
                                        ForEach(Array(years), id: \.self) { Text("\(String($0))년").tag($0) }
                                    }
                                    Picker("월", selection: $month) {
                                        ForEach(1...12, id: \.self) { Text("\($0)월").tag($0) }
                                    }
                                    Picker("일", selection: $day) {
                                        ForEach(1...31, id: \.self) { Text("\($0)일").tag($0) }
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(DT.ink)
                            }

                            field("출생 지역") {
                                Button {
                                    showRegionPicker = true
                                } label: {
                                    HStack {
                                        Text(region)
                                            .font(DT.sans(15))
                                            .foregroundStyle(DT.ink)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(DT.inkSoft)
                                    }
                                }
                            }

                            Toggle("태어난 시간을 알아요", isOn: $knowsTime)
                                .font(DT.sans(14))
                                .tint(DT.accent)

                            if knowsTime {
                                field("태어난 시간") {
                                    HStack {
                                        Picker("시", selection: $hour) {
                                            ForEach(0...23, id: \.self) { Text(String(format: "%02d시", $0)).tag($0) }
                                        }
                                        Picker("분", selection: $minute) {
                                            ForEach(0...59, id: \.self) { Text(String(format: "%02d분", $0)).tag($0) }
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(DT.ink)
                                }
                            }
                        }
                    }

                    Button {
                        var profile = UserProfile(
                            year: year, month: month, day: day,
                            hour: knowsTime ? hour : nil,
                            gender: gender
                        )
                        profile.name = name
                        profile.minute = knowsTime ? minute : 0
                        profile.calendar = calendarType
                        profile.isLeapMonth = calendarType == "lunar" && isLeapMonth
                        profile.region = region
                        appState.profile = profile
                    } label: {
                        Text("운세 보러 가기")
                            .font(DT.sans(16, .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(DT.accent)
                            .clipShape(RoundedRectangle(cornerRadius: DT.radius))
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showRegionPicker) {
            RegionPickerSheet(selection: $region)
        }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(DT.sans(12, .semibold))
                .foregroundStyle(DT.inkSoft)
            content()
        }
    }
}
