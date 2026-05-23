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

          create slice page|feature|entity <name> [--root <path>] [--dry-run]
              Generate an FSD slice in an existing app source root.

          create module <Name> --output <path> [--dry-run]
              Generate a standalone SwiftPM module island.

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
          swift tools/fsd-ios.swift create slice feature export-report --root Sources/App
          swift tools/fsd-ios.swift create module Reporting --output ../ReportingModule
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
          swift tools/fsd-ios.swift create slice page|feature|entity <name> [--root <path>] [--dry-run]
          swift tools/fsd-ios.swift create module <Name> --output <path> [--dry-run]

        Template kinds:
          app     Full SwiftUI app starter under templates/fsd-ios.
          spm     Local Swift Package module island under templates/fsd-ios-spm.
          slice   Page, feature, or entity slice in an app source root.
          module  Standalone SwiftPM module island.
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

        guard fileManager.createFile(atPath: outputFileURL.path, contents: nil),
              fileManager.createFile(atPath: errorFileURL.path, contents: nil)
        else {
            throw CLIError.launchFailed(
                "Could not create temporary output files: \(outputFileURL.path), \(errorFileURL.path)"
            )
        }

        guard let writableOutput = FileHandle(forWritingAtPath: outputFileURL.path),
              let writableError = FileHandle(forWritingAtPath: errorFileURL.path)
        else {
            throw CLIError.launchFailed(
                "Could not open temporary output files: \(outputFileURL.path), \(errorFileURL.path)"
            )
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

struct GeneratedFile {
    let relativePath: String
    let contents: String
}

struct GeneratedPlan {
    let title: String
    let outputURL: URL
    let files: [GeneratedFile]
}

enum GeneratedCreateError: Error, CustomStringConvertible {
    case invalidUsage(String)
    case conflict(String)

    var description: String {
        switch self {
        case .invalidUsage(let message), .conflict(let message):
            return message
        }
    }
}

enum SliceKind: String {
    case page
    case feature
    case entity

    var layer: String {
        switch self {
        case .page:
            return "pages"
        case .feature:
            return "features"
        case .entity:
            return "entities"
        }
    }

}

func titleCaseWords(from kebabName: String) -> String {
    kebabName
        .split(separator: "-")
        .map { word in
            guard let first = word.first else {
                return ""
            }

            return String(first).uppercased() + String(word.dropFirst())
        }
        .joined(separator: " ")
}

func pascalCase(from kebabName: String) -> String {
    kebabName
        .split(separator: "-")
        .map { word in
            guard let first = word.first else {
                return ""
            }

            return String(first).uppercased() + String(word.dropFirst())
        }
        .joined()
}

func isValidSliceName(_ value: String) -> Bool {
    let reservedSegments: Set<String> = ["api", "assets", "config", "lib", "model", "testing", "ui"]
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")

    guard !value.isEmpty,
          !reservedSegments.contains(value),
          value.unicodeScalars.allSatisfy({ allowed.contains($0) }),
          let first = value.unicodeScalars.first,
          CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz").contains(first),
          let last = value.unicodeScalars.last,
          CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").contains(last)
    else {
        return false
    }

    return !value.contains("--")
}

func isValidSwiftIdentifier(_ value: String) -> Bool {
    let swiftKeywords: Set<String> = [
        "Any",
        "associatedtype",
        "as",
        "actor",
        "await",
        "break",
        "case",
        "catch",
        "class",
        "continue",
        "default",
        "defer",
        "deinit",
        "do",
        "else",
        "enum",
        "extension",
        "false",
        "fileprivate",
        "for",
        "func",
        "guard",
        "if",
        "import",
        "in",
        "init",
        "inout",
        "internal",
        "is",
        "let",
        "nil",
        "open",
        "operator",
        "private",
        "protocol",
        "public",
        "repeat",
        "rethrows",
        "return",
        "self",
        "static",
        "struct",
        "subscript",
        "super",
        "switch",
        "throws",
        "true",
        "try",
        "typealias",
        "var",
        "where",
        "while",
    ]

    guard !swiftKeywords.contains(value) else {
        return false
    }

    guard let first = value.unicodeScalars.first,
          CharacterSet(charactersIn: "_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz").contains(first)
    else {
        return false
    }

    let allowed = CharacterSet(charactersIn: "_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
    return value.unicodeScalars.allSatisfy { allowed.contains($0) }
}

func createSlicePlan(kind: SliceKind, name: String, rootPath: String) throws -> GeneratedPlan {
    guard isValidSliceName(name) else {
        throw GeneratedCreateError.invalidUsage(
            "slice name must be kebab-case business language, for example `item-details`"
        )
    }

    let typeName = pascalCase(from: name)
    let title = titleCaseWords(from: name)
    let rootURL = URL(fileURLWithPath: rootPath).standardizedFileURL
    let sliceRelativePath = "\(kind.layer)/\(name)"
    let files: [GeneratedFile]

    switch kind {
    case .page:
        files = [
            GeneratedFile(
                relativePath: "\(sliceRelativePath)/README.md",
                contents: "# \(title) Page\n\nFSD page slice generated by `fsd-ios create slice`.\n"
            ),
            GeneratedFile(
                relativePath: "\(sliceRelativePath)/ui/\(typeName)Page.swift",
                contents:
                    """
                    import SwiftUI

                    struct \(typeName)Page: View {
                        var body: some View {
                            Text("\(title)")
                        }
                    }

                    """
            ),
        ]
    case .feature:
        files = [
            GeneratedFile(
                relativePath: "\(sliceRelativePath)/README.md",
                contents: "# \(title) Feature\n\nFSD feature slice generated by `fsd-ios create slice`.\n"
            ),
            GeneratedFile(
                relativePath: "\(sliceRelativePath)/model/\(typeName)Action.swift",
                contents:
                    """
                    struct \(typeName)Action {
                        func callAsFunction() {
                        }
                    }

                    """
            ),
            GeneratedFile(
                relativePath: "\(sliceRelativePath)/ui/\(typeName)Button.swift",
                contents:
                    """
                    import SwiftUI

                    struct \(typeName)Button: View {
                        let action: \(typeName)Action

                        init(action: \(typeName)Action = \(typeName)Action()) {
                            self.action = action
                        }

                        var body: some View {
                            Button("\(title)") {
                                action()
                            }
                        }
                    }

                    """
            ),
        ]
    case .entity:
        files = [
            GeneratedFile(
                relativePath: "\(sliceRelativePath)/README.md",
                contents: "# \(title) Entity\n\nFSD entity slice generated by `fsd-ios create slice`.\n"
            ),
            GeneratedFile(
                relativePath: "\(sliceRelativePath)/model/\(typeName).swift",
                contents:
                    """
                    import Foundation

                    struct \(typeName) {
                        let id = UUID()
                    }

                    """
            ),
            GeneratedFile(
                relativePath: "\(sliceRelativePath)/ui/\(typeName)Row.swift",
                contents:
                    """
                    import SwiftUI

                    struct \(typeName)Row: View {
                        let model: \(typeName)

                        var body: some View {
                            Text(model.id.uuidString)
                        }
                    }

                    """
            ),
        ]
    }

    return GeneratedPlan(title: "FSD slice", outputURL: rootURL, files: files)
}

func createModulePlan(name: String, outputPath: String) throws -> GeneratedPlan {
    guard isValidSwiftIdentifier(name) else {
        throw GeneratedCreateError.invalidUsage("module name must be a valid Swift identifier")
    }

    let outputURL = URL(fileURLWithPath: outputPath).standardizedFileURL
    let files = [
        GeneratedFile(
            relativePath: "Package.swift",
            contents:
                """
                // swift-tools-version: 6.1

                import PackageDescription

                let package = Package(
                    name: "\(name)",
                    platforms: [
                        .iOS(.v17),
                        .macOS(.v14),
                    ],
                    products: [
                        .library(name: "\(name)", targets: ["\(name)"]),
                    ],
                    targets: [
                        .target(name: "\(name)"),
                        .testTarget(name: "\(name)Tests", dependencies: ["\(name)"]),
                    ]
                )

                """
        ),
        GeneratedFile(
            relativePath: "README.md",
            contents:
                """
                # \(name)

                SwiftPM module island generated by `fsd-ios create module`.

                """
        ),
        GeneratedFile(
            relativePath: "Sources/\(name)/\(name)Module.swift",
            contents:
                """
                public struct \(name)Module {
                    public init() {
                    }

                    public var name: String {
                        "\(name)"
                    }
                }

                """
        ),
        GeneratedFile(
            relativePath: "Tests/\(name)Tests/\(name)Tests.swift",
            contents:
                """
                import Testing
                @testable import \(name)

                @Test func exposesModuleName() {
                    #expect(\(name)Module().name == "\(name)")
                }

                """
        ),
    ]

    return GeneratedPlan(title: "FSD module", outputURL: outputURL, files: files)
}

func validateGeneratedPlan(_ plan: GeneratedPlan) throws {
    var isDirectory: ObjCBool = false

    if fileManager.fileExists(atPath: plan.outputURL.path, isDirectory: &isDirectory),
       !isDirectory.boolValue {
        throw GeneratedCreateError.conflict("Output path exists and is not a directory: \(plan.outputURL.path)")
    }

    var parent = plan.outputURL.deletingLastPathComponent()

    while parent.path != parent.deletingLastPathComponent().path {
        var parentIsDirectory: ObjCBool = false

        if fileManager.fileExists(atPath: parent.path, isDirectory: &parentIsDirectory) {
            guard parentIsDirectory.boolValue else {
                throw GeneratedCreateError.conflict("Output parent exists and is not a directory: \(parent.path)")
            }

            break
        }

        parent = parent.deletingLastPathComponent()
    }

    for file in plan.files {
        let destinationURL = plan.outputURL.appendingPathComponent(file.relativePath)

        if fileManager.fileExists(atPath: destinationURL.path) {
            throw GeneratedCreateError.conflict("Destination file already exists: \(destinationURL.path)")
        }
    }
}

func materializeGeneratedPlan(_ plan: GeneratedPlan) throws {
    try validateGeneratedPlan(plan)

    for file in plan.files {
        let destinationURL = plan.outputURL.appendingPathComponent(file.relativePath)

        try fileManager.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try file.contents.write(to: destinationURL, atomically: true, encoding: .utf8)
    }
}

func printGeneratedPlan(_ plan: GeneratedPlan, dryRun: Bool) {
    if dryRun {
        print("\(plan.title) create dry run:")
    } else {
        print("\(plan.title) created: \(plan.outputURL.path)")
    }

    print("Output: \(plan.outputURL.path)")

    for file in plan.files.sorted(by: { $0.relativePath < $1.relativePath }) {
        print("create \(file.relativePath)")
    }

    print(dryRun ? "Planned files: \(plan.files.count)" : "Created files: \(plan.files.count)")
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
        throw CLIError.invalidUsage("create requires a kind: app, spm, slice, or module")
    }

    if kind == "--help" || kind == "-h" {
        printCreateUsage()
        return []
    }

    switch kind {
    case "app":
        return try parseTemplateCreateArguments(
            kind: kind,
            templatePath: repoPath("templates/fsd-ios"),
            arguments: arguments
        )
    case "spm":
        return try parseTemplateCreateArguments(
            kind: kind,
            templatePath: repoPath("templates/fsd-ios-spm"),
            arguments: arguments
        )
    case "slice", "module":
        return []
    default:
        throw CLIError.invalidUsage("unknown create kind `\(kind)`. Use `app`, `spm`, `slice`, or `module`.")
    }
}

func parseTemplateCreateArguments(kind: String, templatePath: String, arguments: [String]) throws -> [String] {
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

func runCreateSlice(_ arguments: [String]) throws -> Int32 {
    guard let rawKind = arguments.first else {
        throw CLIError.invalidUsage("create slice requires a kind: page, feature, or entity")
    }

    if rawKind == "--help" || rawKind == "-h" {
        printCreateUsage()
        return 0
    }

    guard let kind = SliceKind(rawValue: rawKind) else {
        throw CLIError.invalidUsage("unknown slice kind `\(rawKind)`. Use `page`, `feature`, or `entity`.")
    }

    guard arguments.count >= 2 else {
        throw CLIError.invalidUsage("create slice \(rawKind) requires a slice name")
    }

    let name = arguments[1]
    var sourceRootPath = repoPath("FSDDemoApp")
    var dryRun = false
    var index = 2

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--help", "-h":
            printCreateUsage()
            return 0
        case "--root":
            index += 1
            guard index < arguments.count else {
                throw CLIError.invalidUsage("--root requires a value")
            }
            sourceRootPath = absolutePath(arguments[index])
        case "--dry-run":
            dryRun = true
        default:
            throw CLIError.invalidUsage("unknown create slice option `\(argument)`")
        }

        index += 1
    }

    let plan = try createSlicePlan(kind: kind, name: name, rootPath: sourceRootPath)

    if dryRun {
        try validateGeneratedPlan(plan)
        printGeneratedPlan(plan, dryRun: true)
    } else {
        try materializeGeneratedPlan(plan)
        printGeneratedPlan(plan, dryRun: false)
    }

    return 0
}

func runCreateModule(_ arguments: [String]) throws -> Int32 {
    guard let name = arguments.first else {
        throw CLIError.invalidUsage("create module requires a module name")
    }

    if name == "--help" || name == "-h" {
        printCreateUsage()
        return 0
    }

    var output: String?
    var dryRun = false
    var index = 1

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--help", "-h":
            printCreateUsage()
            return 0
        case "--output":
            index += 1
            guard index < arguments.count else {
                throw CLIError.invalidUsage("--output requires a value")
            }
            output = absolutePath(arguments[index])
        case "--dry-run":
            dryRun = true
        default:
            throw CLIError.invalidUsage("unknown create module option `\(argument)`")
        }

        index += 1
    }

    guard let output else {
        throw CLIError.invalidUsage("create module requires --output")
    }

    let plan = try createModulePlan(name: name, outputPath: output)

    if dryRun {
        try validateGeneratedPlan(plan)
        printGeneratedPlan(plan, dryRun: true)
    } else {
        try materializeGeneratedPlan(plan)
        printGeneratedPlan(plan, dryRun: false)
    }

    return 0
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
        if commandArguments.first == "slice" {
            return try runCreateSlice(Array(commandArguments.dropFirst()))
        }

        if commandArguments.first == "module" {
            return try runCreateModule(Array(commandArguments.dropFirst()))
        }

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
} catch let error as GeneratedCreateError {
    print("error: \(error.description)")
    print("Run `swift tools/fsd-ios.swift create --help` for usage.")
    exit(2)
} catch {
    print("error: \(error.localizedDescription)")
    exit(1)
}
