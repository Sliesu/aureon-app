//
//  SectionHeader.swift
//  aureon-app
//
//  Vault Hero 标题模板：kicker + 金渐变大标题 + 说明文案。
//  对齐 Web 版跨页面一致的 Hero 结构（Dashboard / Account / Advice / Strategy）。
//

import SwiftUI

struct SectionHeader: View {
    let kicker: String
    let title: String
    var subtitle: String?
    var trailing: (() -> AnyView)?

    init(kicker: String, title: String, subtitle: String? = nil) {
        self.kicker = kicker
        self.title = title
        self.subtitle = subtitle
        self.trailing = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(kicker)
                        .aureonKicker()
                    Text(title)
                        .font(AureonFont.display(26, weight: .semibold))
                        .foregroundStyle(AureonPalette.goldGradient)
                }
                Spacer()
            }
            if let subtitle {
                Text(subtitle)
                    .font(AureonFont.body(14))
                    .foregroundStyle(AureonPalette.mutedSlate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
