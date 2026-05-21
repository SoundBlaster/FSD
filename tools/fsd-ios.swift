#!/usr/bin/env swift
//
//  fsd-ios.swift
//  FSDDemoApp
//
//  Unified local CLI for the FSD iOS reference tooling.
//

import Foundation

struct CommandResult {
    let exitCode: Int32
    let standardOutput: String
    let standardError: String
}

enum CLIError: Error, CustomStringConvertible {
    case invalidUsage(String)
    case launchFailed(String)

    var description: String {
        switch self {
        case .invalidUsage(let message), .launchFailed(let message):
            return message
        }
    }
}

let fileManager = FileManager.default
let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)

func printUsage() {
    print(
        """
        Usage:
          swift tools/fsd-ios.swift <command> [options]

        Commands:
          lint [--root <path>] [--strict] [--architecture]
              Run the FSD structure and optional architecture lint.

          harmonize [--root <path>]
              Print read-only FSD refactoring suggestions.

          create app --name <Name> --output <path> [--dry-run]
              Materialize the full app starter template.

          create spm --name <Name> --output <path> [--dry-run]
              Materialize the SwiftPM module-island template for legacy adoption.

          validate template [--template <path>]
              Validate a copyable template bundle.

          doctor
              Check local toolchain, required files, and quick FSD commands.

        Examples:
          swift tools/fsd-ios.swift lint --root FSDDemoApp --strict --architecture
          swift tools/fsd-ios.swift create app --name MyApp --output ../MyApp
          swift tools/fsd-ios.swift create spm --name LegacyFSD --output ../LegacyFSDModules
          swift tools/fsd-ios.swift doctor
        """
    )
}

func printCreateUsage() {
    print(
        """
        Usage:
          swift tools/fsd-ios.swift create app --name <Name> --output <path> [--dry-run]
          swift tools/fsd-ios.swift create spm --name <Name> --output <path> [--dry-run]

        Template kinds:
          app  Full SwiftUI app starter under templates/fsd-ios.
          spm  Local Swift Package module island under templates/fsd-ios-spm.
        """
    )
}

func runProcess(
    _ command: String,
    _ arguments: [String],
    inheritIO: Bool = true
) throws -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [command] + arguments

    if inheritIO {
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
    }

    let outputPipe = Pipe()
    let errorPipe = Pipe()

    if !inheritIO {
        process.standardOutput = outputPipe
        process.standardError = errorPipe
    }

    do {
        try process.run()
    } catch {
        throw CLIError.launchFailed("Could not run `\(command)`: \(error.localizedDescription)")
    }

    process.waitUntilExit()

    guard !inheritIO else {
        return CommandResult(exitCode: process.terminationStatus, standardOutput: "", standardError: "")
    }

    let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    return CommandResult(
        exitCode: process.terminationStatus,
        standardOutput: output,
        standardError: error
    )
}

func resolveToolScript(_ name: String) -> String {
    let cwdCandidate = currentDirectory
        .appendingPathComponent("tools")
        .appendingPathComponent(name)

    if fileManager.fileExists(atPath: cwdCandidate.path) {
        return cwdCandidate.path
    }

    let scriptPath = CommandLine.arguments[0]
    let scriptURL = URL(fileURLWithPath: scriptPath, relativeTo: currentDirectory)
        .standardizedFileURL
    let siblingCandidate = scriptURL
        .deletingLastPathComponent()
        .appendingPathComponent(name)

    if fileManager.fileExists(atPath: siblingCandidate.path) {
        return siblingCandidate.path
    }

    return "tools/\(name)"
}

func runSwiftScript(_ scriptName: String, arguments: [String]) throws -> Int32 {
    let result = try runProcess("swift", [resolveToolScript(scriptName)] + arguments)
    return result.exitCode
}

func parseCreateArguments(_ arguments: [String]) throws -> [String] {
    guard let kind = arguments.first else {
        throw CLIError.invalidUsage("create requires a template kind: app or spm")
    }

    if kind == "--help" || kind == "-h" {
        printCreateUsage()
        return []
    }

    let templatePath: String

    switch kind {
    case "app":
        templatePath = "templates/fsd-ios"
    case "spm":
        templatePath = "templates/fsd-ios-spm"
    default:
        throw CLIError.invalidUsage("unknown template kind `\(kind)`. Use `app` or `spm`.")
    }

    var name: String?
    var output: String?
    var dryRun = false
    var index = 1

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--help", "-h":
            printCreateUsage()
            return []
        case "--name", "--app-name":
            index += 1
            guard index < arguments.count else {
                throw CLIError.invalidUsage("\(argument) requires a value")
            }
            name = arguments[index]
        case "--output":
            index += 1
            guard index < arguments.count else {
                throw CLIError.invalidUsage("--output requires a value")
            }
            output = arguments[index]
        case "--dry-run":
            dryRun = true
        default:
            throw CLIError.invalidUsage("unknown create option `\(argument)`")
        }

        index += 1
    }

    guard let name else {
        throw CLIError.invalidUsage("create \(kind) requires --name")
    }

    guard let output else {
        throw CLIError.invalidUsage("create \(kind) requires --output")
    }

    var mappedArguments = [
        "--template",
        templatePath,
        "--app-name",
        name,
        "--output",
        output,
    ]

    if dryRun {
        mappedArguments.append("--dry-run")
    }

    return mappedArguments
}

func printDoctorCheck(_ title: String, result: CommandResult) -> Bool {
    if result.exitCode == 0 {
        let summary = result.standardOutput
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
            .map(String.init)
        print("[ok] \(title)\(summary.map { " - \($0)" } ?? "")")
        return true
    }

    print("[fail] \(title)")

    let output = result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    let error = result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)

    if !output.isEmpty {
        print(output)
    }

    if !error.isEmpty {
        print(error)
    }

    return false
}

func checkRequiredPath(_ path: String) -> Bool {
    if fileManager.fileExists(atPath: path) {
        print("[ok] required path exists - \(path)")
        return true
    }

    print("[fail] required path missing - \(path)")
    return false
}

func runDoctor() throws -> Int32 {
    print("FSD iOS doctor")

    var failedChecks = 0

    let requiredPaths = [
        "FSDDemoApp",
        "Makefile",
        "templates/fsd-ios/template.yaml",
        "templates/fsd-ios-spm/template.yaml",
        resolveToolScript("fsd-lint.swift"),
        resolveToolScript("fsd-harmonize.swift"),
        resolveToolScript("fsd-template-create.swift"),
        resolveToolScript("fsd-template-validate.swift"),
    ]

    for path in requiredPaths where !checkRequiredPath(path) {
        failedChecks += 1
    }

    let commandChecks: [(String, String, [String])] = [
        ("Swift toolchain", "swift", ["--version"]),
        ("Xcode toolchain", "xcodebuild", ["-version"]),
        ("Git", "git", ["--version"]),
        (
            "FSD architecture lint",
            "swift",
            [resolveToolScript("fsd-lint.swift"), "--root", "FSDDemoApp", "--strict", "--architecture"]
        ),
        (
            "Template validator",
            "swift",
            [resolveToolScript("fsd-template-validate.swift"), "--template", "templates/fsd-ios"]
        ),
        (
            "SPM template describe",
            "swift",
            ["package", "--package-path", "templates/fsd-ios-spm", "describe"]
        ),
    ]

    for check in commandChecks {
        let result = try runProcess(check.1, check.2, inheritIO: false)

        if !printDoctorCheck(check.0, result: result) {
            failedChecks += 1
        }
    }

    if failedChecks == 0 {
        print("Doctor finished: all checks passed")
        return 0
    }

    print("Doctor finished: \(failedChecks) check(s) failed")
    return 1
}

func runCLI(_ arguments: [String]) throws -> Int32 {
    guard let command = arguments.first else {
        printUsage()
        return 0
    }

    let commandArguments = Array(arguments.dropFirst())

    switch command {
    case "--help", "-h", "help":
        printUsage()
        return 0
    case "lint":
        return try runSwiftScript("fsd-lint.swift", arguments: commandArguments)
    case "harmonize":
        return try runSwiftScript("fsd-harmonize.swift", arguments: commandArguments)
    case "create":
        let mappedArguments = try parseCreateArguments(commandArguments)
        guard !mappedArguments.isEmpty else {
            return 0
        }
        return try runSwiftScript("fsd-template-create.swift", arguments: mappedArguments)
    case "validate":
        guard commandArguments.isEmpty || commandArguments.first == "template" else {
            throw CLIError.invalidUsage("validate currently supports only `template`")
        }

        let templateArguments = commandArguments.first == "template"
            ? Array(commandArguments.dropFirst())
            : commandArguments
        return try runSwiftScript("fsd-template-validate.swift", arguments: templateArguments)
    case "doctor":
        guard commandArguments.isEmpty else {
            throw CLIError.invalidUsage("doctor does not accept options")
        }
        return try runDoctor()
    default:
        throw CLIError.invalidUsage("unknown command `\(command)`")
    }
}

do {
    let exitCode = try runCLI(Array(CommandLine.arguments.dropFirst()))
    exit(exitCode)
} catch let error as CLIError {
    print("error: \(error.description)")
    print("Run `swift tools/fsd-ios.swift --help` for usage.")
    exit(2)
} catch {
    print("error: \(error.localizedDescription)")
    exit(1)
}
