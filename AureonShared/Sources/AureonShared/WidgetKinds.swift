//
//  WidgetKinds.swift
//  AureonShared
//
//  Widget kind 标识符，主 App（请求刷新）与 Extension（注册 Widget）共用，
//  避免字符串硬编码在两端漂移。
//

public enum AureonWidgetKind {
    public static let watchlist = "AureonWatchlistWidget"
    public static let strategy = "AureonStrategyWidget"
}
