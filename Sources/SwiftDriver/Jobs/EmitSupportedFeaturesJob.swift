//===---- EmitSupportedFeatures.swift - Swift Compiler Features Info Job ----===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===////

import TSCBasic

/// Describes information about the compiler's supported arguments and features
@_spi(Testing) public struct SupportedCompilerFeatures: Codable {
  var SupportedArguments: [String]
  var SupportedFeatures: [String]
}

extension Toolchain {
  func emitSupportedCompilerFeaturesJob(requiresInPlaceExecution: Bool = false,
                                        swiftCompilerPrefixArgs: [String]) throws -> Job {
    var commandLine: [Job.ArgTemplate] = swiftCompilerPrefixArgs.map { Job.ArgTemplate.flag($0) }
    var inputs: [TypedVirtualPath] = []
    commandLine.append(contentsOf: [.flag("-frontend"),
                                    .flag("-emit-supported-features")])

    // This action does not require any input files, but all frontend actions require
    // at least one so we fake it.
    // FIXME: Teach -emit-supported-features to not expect any inputs, like -print-target-info does.
    let dummyInputPath = VirtualPath.temporaryWithKnownContents(.init("dummyInput.swift"),
                                                                "".data(using: .utf8)!)
    commandLine.appendPath(dummyInputPath)
    inputs.append(TypedVirtualPath(file: dummyInputPath, type: .swift))
    
    return Job(
      moduleName: "",
      kind: .emitSupportedFeatures,
      tool: .absolute(try getToolPath(.swiftCompiler)),
      commandLine: commandLine,
      displayInputs: [],
      inputs: inputs,
      primaryInputs: [],
      outputs: [.init(file: .standardOutput, type: .jsonCompilerFeatures)],
      requiresInPlaceExecution: requiresInPlaceExecution,
      supportsResponseFiles: false
    )
  }
}

extension Driver {
  static func computeSupportedCompilerFeatures(of toolchain: Toolchain, hostTriple: Triple,
                                               swiftCompilerPrefixArgs: [String],
                                               fileSystem: FileSystem,
                                               executor: DriverExecutor, env: [String: String])
  throws -> Set<String> {
    // If libSwiftScan library is present, use it to query
    let swiftScanLibPath = try Self.getScanLibPath(of: toolchain,
                                                   hostTriple: hostTriple,
                                                   env: env)

    if fileSystem.exists(swiftScanLibPath) {
      let libSwiftScanInstance = try SwiftScan(dylib: swiftScanLibPath)
      if libSwiftScanInstance.canQuerySupportedArguments() {
        return try libSwiftScanInstance.querySupportedArguments()
      }
    }

    // Fallback to invoking `swift-frontend -emit-supported-features`
    let frontendFeaturesJob =
      try toolchain.emitSupportedCompilerFeaturesJob(swiftCompilerPrefixArgs:
                                                      swiftCompilerPrefixArgs)
    let decodedSupportedFlagList = try executor.execute(
      job: frontendFeaturesJob,
      capturingJSONOutputAs: SupportedCompilerFeatures.self,
      forceResponseFiles: false,
      recordedInputModificationDates: [:]).SupportedArguments
    return Set(decodedSupportedFlagList)
  }
}