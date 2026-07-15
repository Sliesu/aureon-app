//
//  AureonWidgetsBundle.swift
//  AureonWidgets
//
//  Widget Extension 的唯一入口：注册两个桌面小组件与策略 Live Activity。
//

import SwiftUI
import WidgetKit

@main
struct AureonWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AureonWatchlistWidget()
        AureonStrategyWidget()
        AureonStrategyActivityWidget()
    }
}
