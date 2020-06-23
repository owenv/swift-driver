// swift-tools-version:5.3
import PackageDescription
import class Foundation.ProcessInfo

let package = Package(
  name: "swift-driver",
  platforms: [
    .macOS(.v10_10),
  ],
  products: [
    .executable(
      name: "swift-driver",
      targets: ["swift-driver"]),
    .executable(
      name: "swift-help",
      targets: ["swift-help"]),
    .library(
      name: "SwiftDriver",
      targets: ["SwiftDriver"]),
    .library(
      name: "SwiftOptions",
      targets: ["SwiftOptions"]),
  ],
  targets: [
    /// The driver library.
    .target(
      name: "SwiftDriver",
      dependencies: ["SwiftOptions",
                     .product(name: "SwiftToolsSupport-auto",
                              package: "swift-tools-support-core"),
                     "Yams"],
      exclude: ["CMakeLists.txt"]),
    .testTarget(
      name: "SwiftDriverTests",
      dependencies: ["SwiftDriver", "swift-driver"],
      resources: [.copy("TestInputs")]),

    /// The options library.
    .target(
      name: "SwiftOptions",
      dependencies: [.product(name: "SwiftToolsSupport-auto",
                              package: "swift-tools-support-core")],
      exclude: ["CMakeLists.txt"]),
    .testTarget(
      name: "SwiftOptionsTests",
      dependencies: ["SwiftOptions"]),

    /// The primary driver executable.
    .target(
      name: "swift-driver",
      dependencies: ["SwiftDriver"],
      exclude: ["CMakeLists.txt"]),

    /// The help executable.
    .target(
      name: "swift-help",
      dependencies: ["SwiftOptions"],
      exclude: ["CMakeLists.txt"]),

    /// The `makeOptions` utility (for importing option definitions).
    .target(
      name: "makeOptions",
      dependencies: []),
  ],
  cxxLanguageStandard: .cxx14
)

if ProcessInfo.processInfo.environment["SWIFT_DRIVER_LLBUILD_FWK"] == nil {
    if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
        package.dependencies += [
          .package(name: "llbuild", url: "https://github.com/apple/swift-llbuild.git", .branch("master")),
        ]
    } else {
        // In Swift CI, use a local path to llbuild to interoperate with tools
        // like `update-checkout`, which control the sources externally.
        package.dependencies += [
          .package(name: "llbuild", path: "../llbuild"),
        ]
    }
  package.targets.first(where: { $0.name == "SwiftDriver" })!.dependencies +=
    [.product(name: "llbuildSwift", package: "llbuild")]
}

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
  package.dependencies += [
    .package(url: "https://github.com/apple/swift-tools-support-core.git", .branch("master")),
    .package(url: "https://github.com/jpsim/Yams.git", .branch("master")),
    ]
} else {
    package.dependencies += [
        .package(path: "../swiftpm/swift-tools-support-core"),
        .package(path: "../yams"),
    ]
}
