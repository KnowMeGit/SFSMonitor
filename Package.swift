// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "SFSMonitor",
  products: [
    .library(name: "SFSMonitor", targets: ["SFSMonitor"])
  ],
  dependencies: [],
  targets: [
    .target(name: "SFSMonitor", path: ".", sources: ["SFSMonitor.swift"])
  ]
)
