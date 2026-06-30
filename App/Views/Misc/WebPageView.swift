// 번들 임베딩 웹페이지 표시 — 개인정보처리방침 등 정적 문서를 인앱 WebView로 브라우징

import SwiftUI
import UIKit
import WebKit

/// 앱 번들에 포함된 HTML 파일을 로드하는 WKWebView 래퍼
struct BundledWebView: UIViewRepresentable {
    let resource: String          // 확장자 제외 파일명 (예: "privacy")

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        if let url = Bundle.main.url(forResource: resource, withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}

/// 시트로 표시하는 문서 뷰 (제목 + 닫기 버튼 + 임베딩 웹페이지)
struct DocumentSheet: View {
    let title: String
    let resource: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BundledWebView(resource: resource)
                .background(DT.bg)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .dtCloseToolbar { dismiss() }
        }
    }
}
