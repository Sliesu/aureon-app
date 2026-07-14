//
//  WalkForwardAndScanViews.swift
//  aureon-app
//
//  Walk-forward 分窗结果与参数扫描热力列表，对齐 Web 版高级回测能力。
//

import SwiftUI

struct WalkForwardResultView: View {
    let result: WalkForwardResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("平均样本外收益 \(AureonFormat.percent(result.averageOutSampleReturnPercent))")
                .font(AureonFont.body(13, weight: .semibold))
                .foregroundStyle(AureonPalette.warmWhite)
            ForEach(result.windows) { window in
                HStack {
                    Text(window.windowLabel).font(AureonFont.mono(12)).foregroundStyle(AureonPalette.mutedSlate)
                    Spacer()
                    Text("样本内 \(AureonFormat.percent(window.inSampleReturnPercent, decimals: 1))")
                        .font(AureonFont.mono(11)).foregroundStyle(AureonPalette.signalHold)
                    Text("样本外 \(AureonFormat.percent(window.outSampleReturnPercent, decimals: 1))")
                        .font(AureonFont.mono(11, weight: .semibold))
                        .foregroundStyle(window.outSampleReturnPercent >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct ParamScanResultView: View {
    let result: ParamScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(result.points) { point in
                HStack {
                    if point.id == result.bestPointId {
                        Image(systemName: "crown.fill").foregroundStyle(AureonPalette.gold500).font(.system(size: 11))
                    }
                    Text(point.paramLabel).font(AureonFont.mono(11)).foregroundStyle(AureonPalette.mutedSlate)
                    Spacer()
                    Text(AureonFormat.percent(point.totalReturnPercent, decimals: 1))
                        .font(AureonFont.mono(12, weight: .semibold))
                        .foregroundStyle(point.totalReturnPercent >= 0 ? AureonPalette.signalBuy : AureonPalette.signalSell)
                    Text("回撤 \(AureonFormat.percent(point.maxDrawdownPercent, decimals: 1, showsSign: false))")
                        .font(AureonFont.mono(10)).foregroundStyle(AureonPalette.mutedSlate)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
