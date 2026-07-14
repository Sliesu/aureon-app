//
//  ReplayControlBar.swift
//  aureon-app
//
//  K 线回放控制条，对齐 Web 版桌面特色回放 scrubber（移动端简化为步进按钮）。
//

import SwiftUI

struct ReplayControlBar: View {
    let isReplaying: Bool
    let onToggle: () -> Void
    let onStepBack: () -> Void
    let onStepForward: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Label(isReplaying ? "退出回放" : "开始回放", systemImage: isReplaying ? "stop.circle.fill" : "play.circle.fill")
            }
            .buttonStyle(GhostButtonStyle())

            if isReplaying {
                Button(action: onStepBack) {
                    Image(systemName: "backward.frame.fill")
                }
                .buttonStyle(GhostButtonStyle())

                Button(action: onStepForward) {
                    Image(systemName: "forward.frame.fill")
                }
                .buttonStyle(GhostButtonStyle())
            }
            Spacer()
        }
        .accessibilityElement(children: .contain)
    }
}
