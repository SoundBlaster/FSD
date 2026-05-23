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

struct DoctorCheckResult {
    let name: String
    let passed: Bool
    let message: String
    let exitCode: Int32?
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
let originalWorkingDirectoryURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    .standardizedFileURL
let invokedScriptURL = URL(
    fileURLWithPath: CommandLine.arguments[0],
    relativeTo: originalWorkingDirectoryURL
)
.standardizedFileURL
let toolsDirectoryURL = invokedScriptURL.deletingLastPathComponent()
let repoRootURL = toolsDirectoryURL.lastPathComponent == "tools"
    ? toolsDirectoryURL.deletingLastPathComponent()
    : originalWorkingDirectoryURL
let cliVersion = "0.4.0"

func printUsage() {
    print(
        """
        Usage:
          swift tools/fsd-ios.swift <command> [options]

        Commands:
          version, --version
              Print the fsd-ios CLI version.

          lint [--root <path>] [--config <path>] [--strict|--no-strict] [--architecture|--no-architecture] [--format text|json|xcode]
              Run the FSD structure and optional architecture lint.

          harmonize [--root <path>]
              Print read-only FSD refactoring suggestions.

          create app --name <Name> --output <path> [--dry-run]
              Materialize the full app starter template.

          create spm --name <Name> --output <path> [--dry-run]
              Materialize the SwiftPM module-island template for legacy adoption.

          validate template [--template <path>]
              Validate a copyable template bundle.

          doctor [--json]
              Check local toolchain, required files, and quick FSD commands.

        Examples:
          swift tools/fsd-ios.swift lint --root FSDDemoApp --strict --architecture
          swift tools/fsd-ios.swift lint --config .fsd-ios.yml
          swift tools/fsd-ios.swift lint --config .fsd-ios.yml --format xcode
          swift tools/fsd-ios.swift create app --name MyApp --output ../MyApp
          swift tools/fsd-ios.swift create spm --name LegacyFSD --output ../LegacyFSDModules
          swift tools/fsd-ios.swift version
          swift tools/fsd-ios.swift --version
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

func printValidateUsage() {
    print(
        """
        Usage:
          swift tools/fsd-ios.swift validate template [--template <path>]

        Validates a copyable template bundle. If --template is omitted, the
        repository app template is used.
        """
    )
}

func printDoctorUsage() {
    print(
        """
        Usage:
          swift tools/fsd-ios.swift doctor [--json]

        Checks local toolchain, required repository files, strict FSD lint,
        template validation, and SwiftPM template metadata.

        Options:
          --json  Print machine-readable check results.
        """
    )
}

func printVersion() {
    print("fsd-ios \(cliVersion)")
}

func runProcess(
    _ command: String,
    _ arguments: [String],
    inheritIO: Bool = true,
    workingDirectoryURL: URL? = nil
) throws -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [command] + arguments
    process.currentDirectoryURL = workingDirectoryURL

    if inheritIO {
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
    }

    var outputURL: URL?
    var errorURL: URL?
    var outputHandle: FileHandle?
    var errorHandle: FileHandle?

    defer {
        try? outputHandle?.close()
        try? errorHandle?.close()

        if let outputURL {
            try? fileManager.removeItem(at: outputURL)
        }

        if let errorURL {
            try? fileManager.removeItem(at: errorURL)
        }
    }

    if !inheritIO {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let outputFileURL = temporaryDirectory.appendingPathComponent("fsd-ios-\(UUID().uuidString).stdout")
        let errorFileURL = temporaryDirectory.appendingPathComponent("fsd-ios-\(UUID().uuidString).stderr")

        fileManager.createFile(atPath: outputFileURL.path, contents: nil)
        fileManager.createFile(atPath: errorFileURL.path, contents: nil)

        guard let writableOutput = FileHandle(forWritingAtPath: outputFileURL.path),
              let writableError = FileHandle(forWritingAtPath: errorFileURL.path)
        else {
            throw CLIError.launchFailed("Could not create temporary output files")
        }

        outputURL = outputFileURL
        errorURL = errorFileURL
        outputHandle = writableOutput
        errorHandle = writableError

        process.standardOutput = writableOutput
        process.standardError = writableError
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

    try? outputHandle?.close()
    try? errorHandle?.close()
    outputHandle = nil
    errorHandle = nil

    let outputData = outputURL.flatMap { try? Data(contentsOf: $0) } ?? Data()
    let errorData = errorURL.flatMap { try? Data(contentsOf: $0) } ?? Data()
    let output = String(data: outputData, encoding: .utf8) ?? ""
    let error = String(data: errorData, encoding: .utf8) ?? ""

    return CommandResult(
        exitCode: process.terminationStatus,
        standardOutput: output,
        standardError: error
    )
}

func resolveToolScript(_ name: String) -> String {
    let siblingCandidate = toolsDirectoryURL
        .appendingPathComponent(name)
        .standardizedFileURL

    if fileManager.fileExists(atPath: siblingCandidate.path) {
        return siblingCandidate.path
    }

    return repoRootURL
        .appendingPathComponent("tools")
        .appendingPathComponent(name)
        .standardizedFileURL
        .path
}

func repoPath(_ relativePath: String) -> String {
    repoRootURL
        .appendingPathComponent(relativePath)
        .standardizedFileURL
        .path
}

func absolutePath(_ path: String, relativeTo baseURL: URL = originalWorkingDirectoryURL) -> String {
    if path.hasPrefix("/") {
        return URL(fileURLWithPath: path).standardizedFileURL.path
    }

    return baseURL
        .appendingPathComponent(path)
        .standardizedFileURL
        .path
}

func containsHelp(_ arguments: [String]) -> Bool {
    arguments.contains("--help") || arguments.contains("-h")
}

func normalizePathOptions(
    in arguments: [String],
    options: Set<String>,
    defaultOption: (name: String, value: String)? = nil
) -> [String] {
    var normalized: [String] = []
    var index = 0
    var sawDefaultOption = false

    while index < arguments.count {
        let argument = arguments[index]
        normalized.append(argument)

        if options.contains(argument) {
            sawDefaultOption = true
            index += 1

            if index < arguments.count {
                normalized.append(absolutePath(arguments[index]))
            }
        }

        index += 1
    }

    if let defaultOption, !sawDefaultOption {
        normalized.append(defaultOption.name)
        normalized.append(defaultOption.value)
    }

    return normalized
}

func hasOption(_ option: String, in arguments: [String]) -> Bool {
    arguments.contains(option)
}

func hasPositionalLintRoot(in arguments: [String]) -> Bool {
    let optionsWithValues: Set<String> = ["--root", "--config", "--format"]
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        if optionsWithValues.contains(argument) {
            index += 2
            continue
        }

        if argument.hasPrefix("-") {
            index += 1
            continue
        }

        return true
    }

    return false
}

func discoverDefaultConfigPath() -> String? {
    for filename in [".fsd-ios.yml", ".fsd-ios.yaml"] {
        let url = originalWorkingDirectoryURL
            .appendingPathComponent(filename)
            .standardizedFileURL

        if fileManager.fileExists(atPath: url.path) {
            return url.path
        }
    }

    return nil
}

func normalizeLintArguments(_ arguments: [String]) -> [String] {
    var normalized = normalizePathOptions(
        in: arguments,
        options: ["--root", "--config"]
    )

    let hasConfig = hasOption("--config", in: arguments)
    let hasRoot = hasOption("--root", in: arguments) || hasPositionalLintRoot(in: arguments)

    if !hasConfig, let configPath = discoverDefaultConfigPath() {
        normalized.append("--config")
        normalized.append(configPath)
    }

    if !hasRoot, !hasConfig, discoverDefaultConfigPath() == nil {
        normalized.append("--root")
        normalized.append(repoPath("FSDDemoApp"))
    }

    return normalized
}

func runSwiftScript(_ scriptName: String, arguments: [String]) throws -> Int32 {
    let result = try runProcess(
        "swift",
        [resolveToolScript(scriptName)] + arguments,
        workingDirectoryURL: repoRootURL
    )
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
        templatePath = repoPath("templates/fsd-ios")
    case "spm":
        templatePath = repoPath("templates/fsd-ios-spm")
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
        absolutePath(output),
    ]

    if dryRun {
        mappedArguments.append("--dry-run")
    }

    return mappedArguments
}

func firstOutputLine(stdout: String, stderr: String) -> String {
    let output = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let error = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
    let preferredText = output.isEmpty ? error : output
    return preferredText
        .split(separator: "\n", omittingEmptySubsequences: true)
        .first
        .map(String.init) ?? ""
}

func requiredPathCheck(_ path: String) -> DoctorCheckResult {
    let resolvedPath = repoPath(path)

    if fileManager.fileExists(atPath: resolvedPath) {
        return DoctorCheckResult(
            name: "required path: \(path)",
            passed: true,
            message: path,
            exitCode: nil,
            standardOutput: "",
            standardError: ""
        )
    }

    return DoctorCheckResult(
        name: "required path: \(path)",
        passed: false,
        message: "missing: \(path)",
        exitCode: nil,
        standardOutput: "",
        standardError: ""
    )
}

func commandCheck(_ title: String, command: String, arguments: [String]) throws -> DoctorCheckResult {
    let result = try runProcess(
        command,
        arguments,
        inheritIO: false,
        workingDirectoryURL: repoRootURL
    )

    return DoctorCheckResult(
        name: title,
        passed: result.exitCode == 0,
        message: firstOutputLine(stdout: result.standardOutput, stderr: result.standardError),
        exitCode: result.exitCode,
        standardOutput: result.standardOutput,
        standardError: result.standardError
    )
}

func printDoctorText(checks: [DoctorCheckResult]) {
    print("FSD iOS doctor")

    for check in checks {
        if check.passed {
            print("[ok] \(check.name)\(check.message.isEmpty ? "" : " - \(check.message)")")
        } else {
            print("[fail] \(check.name)\(check.message.isEmpty ? "" : " - \(check.message)")")

            let output = check.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            let error = check.standardError.trimmingCharacters(in: .whitespacesAndNewlines)

            if !output.isEmpty {
                print(output)
            }

            if !error.isEmpty {
                print(error)
            }
        }
    }
}

func printDoctorJSON(checks: [DoctorCheckResult]) throws {
    let checkPayloads = checks.map { check -> [String: Any] in
        var payload: [String: Any] = [
            "name": check.name,
            "passed": check.passed,
            "message": check.message,
        ]

        if let exitCode = check.exitCode {
            payload["exitCode"] = exitCode
        }

        return payload
    }

    let payload: [String: Any] = [
        "tool": "fsd-ios",
        "version": cliVersion,
        "repoRoot": repoRootURL.path,
        "passed": checks.allSatisfy(\.passed),
        "checks": checkPayloads,
    ]

    let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    print(String(data: data, encoding: .utf8) ?? "{}")
}

func runDoctor(jsonOutput: Bool) throws -> Int32 {
    let requiredPaths = [
        ".fsd-ios.yml",
        "FSDDemoApp",
        "Makefile",
        "docs/configuration.md",
        "templates/fsd-ios/template.yaml",
        "templates/fsd-ios-spm/template.yaml",
        "tools/fsd-lint.swift",
        "tools/fsd-harmonize.swift",
        "tools/fsd-template-create.swift",
        "tools/fsd-template-validate.swift",
    ]

    var checks = requiredPaths.map(requiredPathCheck)

    let commandChecks: [(String, String, [String])] = [
        ("Swift toolchain", "swift", ["--version"]),
        ("Xcode toolchain", "xcodebuild", ["-version"]),
        ("Git", "git", ["--version"]),
        (
            "FSD architecture lint",
            "swift",
            [resolveToolScript("fsd-lint.swift"), "--root", repoPath("FSDDemoApp"), "--strict", "--architecture"]
        ),
        (
            "FSD config lint",
            "swift",
            [resolveToolScript("fsd-lint.swift"), "--config", repoPath(".fsd-ios.yml"), "--no-strict", "--no-architecture"]
        ),
        (
            "Template validator",
            "swift",
            [resolveToolScript("fsd-template-validate.swift"), "--template", repoPath("templates/fsd-ios")]
        ),
        (
            "SPM template describe",
            "swift",
            ["package", "--package-path", repoPath("templates/fsd-ios-spm"), "describe"]
        ),
    ]

    for check in commandChecks {
        checks.append(try commandCheck(check.0, command: check.1, arguments: check.2))
    }

    if jsonOutput {
        try printDoctorJSON(checks: checks)
        return checks.allSatisfy(\.passed) ? 0 : 1
    }

    printDoctorText(checks: checks)

    if checks.allSatisfy(\.passed) {
        print("Doctor finished: all checks passed")
        return 0
    }

    let failedChecks = checks.filter { !$0.passed }.count
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
    case "--version", "version":
        printVersion()
        return 0
    case "lint":
        let lintArguments = containsHelp(commandArguments)
            ? commandArguments
            : normalizeLintArguments(commandArguments)
        return try runSwiftScript("fsd-lint.swift", arguments: lintArguments)
    case "harmonize":
        let harmonizeArguments = containsHelp(commandArguments)
            ? commandArguments
            : normalizePathOptions(
                in: commandArguments,
                options: ["--root"],
                defaultOption: ("--root", repoPath("FSDDemoApp"))
            )
        return try runSwiftScript("fsd-harmonize.swift", arguments: harmonizeArguments)
    case "create":
        let mappedArguments = try parseCreateArguments(commandArguments)
        guard !mappedArguments.isEmpty else {
            return 0
        }
        return try runSwiftScript("fsd-template-create.swift", arguments: mappedArguments)
    case "validate":
        if commandArguments.isEmpty || containsHelp(commandArguments) && commandArguments.first != "template" {
            printValidateUsage()
            return 0
        }

        guard commandArguments.isEmpty || commandArguments.first == "template" else {
            throw CLIError.invalidUsage("validate currently supports only `template`")
        }

        let rawTemplateArguments = commandArguments.first == "template"
            ? Array(commandArguments.dropFirst())
            : commandArguments
        let templateArguments = containsHelp(rawTemplateArguments)
            ? rawTemplateArguments
            : normalizePathOptions(
                in: rawTemplateArguments,
                options: ["--template"],
                defaultOption: ("--template", repoPath("templates/fsd-ios"))
            )
        return try runSwiftScript("fsd-template-validate.swift", arguments: templateArguments)
    case "doctor":
        if containsHelp(commandArguments) {
            printDoctorUsage()
            return 0
        }

        let jsonOutput = commandArguments.contains("--json")
        let allowedDoctorOptions: Set<String> = ["--json"]

        guard commandArguments.allSatisfy({ allowedDoctorOptions.contains($0) }) else {
            throw CLIError.invalidUsage("doctor accepts only --json")
        }
        return try runDoctor(jsonOutput: jsonOutput)
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
