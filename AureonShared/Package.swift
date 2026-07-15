// swift-tools-version: 6.0
//
//  Package.swift
//  AureonShared
//
//  本地 Swift Package：主 App 与 AureonWidgets（Widget/Live Activity Extension）
//  共享的最小模型与工具，避免通过 Xcode 项目文件手工维护跨 Target 成员归属。
//

import PackageDescription

let package = Package(
    name: "AureonShared",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "AureonShared", targets: ["AureonShared"])
    ],
    targets: [
        .target(name: "AureonShared"),
        .testTarget(name: "AureonSharedTests", dependencies: ["AureonShared"])
    ]
)
