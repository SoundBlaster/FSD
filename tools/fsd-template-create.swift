#!/usr/bin/env swift
//
//  fsd-template-create.swift
//  FSDDemoApp
//
//  Materializes the copyable FSD iOS template package into a new folder.
//

import Foundation

struct TemplateCreateConfiguration {
    let templatePath: String
    let outputPath: String
    let appName: String
    let dryRun: Bool
}

struct MaterializedFile {
    let source: URL
    let relativeSourcePath: String
    let destination: URL
    let relativeDestinationPath: String
    let isText: Bool
}

struct TemplateCreatePlan {
    let outputURL: URL
    let files: [MaterializedFile]
}

struct TemplateCreator {
    private let fileManager = FileManager.default
    private let templateURL: URL
    private let outputURL: URL
    private let placeholder: String
    private let appName: String

    init(templateURL: URL, outputURL: URL, placeholder: String, appName: String) {
        self.templateURL = templateURL
        self.outputURL = outputURL
        self.placeholder = placeholder
        self.appName = appName
    }

    func plan() throws -> TemplateCreatePlan {
        guard directoryExists(templateURL) else {
            throw TemplateCreateError.invalidInput("Template root does not exist: \(templateURL.path)")
        }

        let files = try fileURLs(under: templateURL)

        guard !files.isEmpty else {
            throw TemplateCreateError.invalidInput("Template root has no files: \(templateURL.path)")
        }

        let materializedFiles = files.map { sourceURL in
            let relativePath = relativePath(for: sourceURL, under: templateURL)
            let materializedPath = relativePath.replacingOccurrences(of: placeholder, with: appName)
            let destinationURL = outputURL.appendingPathComponent(materializedPath)

            return MaterializedFile(
                source: sourceURL,
                relativeSourcePath: relativePath,
                destination: destinationURL,
                relativeDestinationPath: materializedPath,
                isText: isTextFile(sourceURL)
            )
        }

        return TemplateCreatePlan(
            outputURL: outputURL,
            files: materializedFiles.sorted { $0.relativeDestinationPath < $1.relativeDestinationPath }
        )
    }

    func materialize(_ plan: TemplateCreatePlan) throws {
        try validate(plan)
        try fileManager.createDirectory(
            at: plan.outputURL,
            withIntermediateDirectories: true
        )

        for file in plan.files {
            try fileManager.createDirectory(
                at: file.destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            if file.isText {
                let source = try String(contentsOf: file.source, encoding: .utf8)
                let materializedSource = source.replacingOccurrences(of: placeholder, with: appName)
                try materializedSource.write(to: file.destination, atomically: true, encoding: .utf8)
            } else {
                try fileManager.copyItem(at: file.source, to: file.destination)
            }
        }

        try validateMaterializedOutput(plan)
    }

    func validate(_ plan: TemplateCreatePlan) throws {
        try validateOutputRoot(plan.outputURL)
        try validateNoDestinationConflicts(plan)
    }

    private func validateOutputRoot(_ outputURL: URL) throws {
        var isDirectory: ObjCBool = false

        if fileManager.fileExists(atPath: outputURL.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw TemplateCreateError.conflict("Output path exists and is not a directory: \(outputURL.path)")
            }

            return
        }

        var ancestor = outputURL.deletingLastPathComponent()

        while ancestor.path != ancestor.deletingLastPathComponent().path {
            var ancestorIsDirectory: ObjCBool = false

            if fileManager.fileExists(atPath: ancestor.path, isDirectory: &ancestorIsDirectory) {
                guard ancestorIsDirectory.boolValue else {
                    throw TemplateCreateError.conflict("Output parent exists and is not a directory: \(ancestor.path)")
                }

                guard fileManager.isWritableFile(atPath: ancestor.path) else {
                    throw TemplateCreateError.conflict("Output parent is not writable: \(ancestor.path)")
                }

                return
            }

            ancestor = ancestor.deletingLastPathComponent()
        }

        throw TemplateCreateError.conflict("No existing parent directory for output path: \(outputURL.path)")
    }

    private func validateNoDestinationConflicts(_ plan: TemplateCreatePlan) throws {
        for file in plan.files where fileManager.fileExists(atPath: file.destination.path) {
            throw TemplateCreateError.conflict("Destination file already exists: \(file.destination.path)")
        }
    }

    private func validateMaterializedOutput(_ plan: TemplateCreatePlan) throws {
        for file in plan.files {
            let expectedRelativePath = file.relativeSourcePath
                .replacingOccurrences(of: placeholder, with: appName)

            guard file.relativeDestinationPath == expectedRelativePath else {
                throw TemplateCreateError.conflict(
                    "Generated path does not match expected placeholder replacement: \(file.relativeDestinationPath)"
                )
            }

            guard file.isText else {
                continue
            }

            let source = try String(contentsOf: file.source, encoding: .utf8)
            let expectedContents = source.replacingOccurrences(of: placeholder, with: appName)
            let generatedContents = try String(contentsOf: file.destination, encoding: .utf8)

            guard generatedContents == expectedContents else {
                throw TemplateCreateError.conflict(
                    "Generated file does not match expected placeholder replacement: \(file.relativeDestinationPath)"
                )
            }
        }
    }

    private func fileURLs(under url: URL) throws -> [URL] {
        var enumerationErrors: [String] = []
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
            options: [],
            errorHandler: { url, error in
                enumerationErrors.append("\(url.path): \(error.localizedDescription)")
                return false
            }
        ) else {
            throw TemplateCreateError.invalidInput("Could not enumerate template root: \(url.path)")
        }

        var files: [URL] = []

        for item in enumerator {
            guard let fileURL = item as? URL else {
                continue
            }

            let values = try fileURL.resourceValues(forKeys: [
                .isDirectoryKey,
                .isRegularFileKey,
                .isSymbolicLinkKey,
            ])

            if values.isSymbolicLink == true {
                throw TemplateCreateError.invalidInput(
                    "Template contains symbolic link, which is not supported: \(relativePath(for: fileURL, under: url))"
                )
            }

            if values.isDirectory == true {
                continue
            }

            guard values.isRegularFile == true else {
                continue
            }

            files.append(fileURL)
        }

        if let firstError = enumerationErrors.first {
            throw TemplateCreateError.invalidInput("Could not enumerate template root: \(firstError)")
        }

        return files
    }

    private func relativePath(for url: URL, under rootURL: URL) -> String {
        let rootPath = rootURL.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        let startIndex = path.index(path.startIndex, offsetBy: rootPath.count)
        return String(path[startIndex...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func isTextFile(_ url: URL) -> Bool {
        let textExtensions: Set<String> = [
            "",
            "md",
            "swift",
            "yml",
            "yaml",
        ]

        return textExtensions.contains(url.pathExtension.lowercased())
    }

    private func directoryExists(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

enum TemplateCreateError: Error, CustomStringConvertible {
    case invalidInput(String)
    case conflict(String)

    var description: String {
        switch self {
        case .invalidInput(let message), .conflict(let message):
            return message
        }
    }
}

func parseTemplateCreateArguments(_ arguments: [String]) -> TemplateCreateConfiguration? {
    var templatePath = "templates/fsd-ios"
    var outputPath: String?
    var appName: String?
    var dryRun = false
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--help", "-h":
            printTemplateCreateUsage()
            return nil
        case "--template":
            index += 1
            guard index < arguments.count else {
                print("error: --template requires a path")
                exit(2)
            }
            templatePath = arguments[index]
        case "--output":
            index += 1
            guard index < arguments.count else {
                print("error: --output requires a path")
                exit(2)
            }
            outputPath = arguments[index]
        case "--app-name":
            index += 1
            guard index < arguments.count else {
                print("error: --app-name requires a Swift module name")
                exit(2)
            }
            appName = arguments[index]
        case "--dry-run":
            dryRun = true
        default:
            if argument.hasPrefix("-") {
                print("error: unknown option \(argument)")
                exit(2)
            }
            print("error: unexpected positional argument \(argument)")
            exit(2)
        }

        index += 1
    }

    guard let outputPath else {
        print("error: --output is required")
        exit(2)
    }

    guard let appName else {
        print("error: --app-name is required")
        exit(2)
    }

    guard isValidSwiftIdentifier(appName) else {
        print("error: --app-name must be a valid Swift identifier")
        exit(2)
    }

    return TemplateCreateConfiguration(
        templatePath: templatePath,
        outputPath: outputPath,
        appName: appName,
        dryRun: dryRun
    )
}

func printTemplateCreateUsage() {
    print(
        """
        Usage:
          swift tools/fsd-template-create.swift --app-name <Name> --output <path> [--template <path>] [--dry-run]

        Materializes the copyable FSD iOS template package:
          - copies template files into the output folder
          - replaces `AppName` in paths and text files
          - refuses to overwrite existing files
          - validates that no `AppName` placeholder remains after materialization

        Options:
          --app-name <Name>   Swift module name to replace `AppName`.
          --output <path>     Destination folder.
          --template <path>   Template package root. Defaults to `templates/fsd-ios`.
          --dry-run           Print planned file operations without writing files.
        """
    )
}

func makeURL(from path: String) -> URL {
    if path.hasPrefix("/") {
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(path)
        .standardizedFileURL
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

guard let configuration = parseTemplateCreateArguments(Array(CommandLine.arguments.dropFirst())) else {
    exit(0)
}

let creator = TemplateCreator(
    templateURL: makeURL(from: configuration.templatePath),
    outputURL: makeURL(from: configuration.outputPath),
    placeholder: "AppName",
    appName: configuration.appName
)

do {
    let plan = try creator.plan()

    if configuration.dryRun {
        try creator.validate(plan)
        print("FSD template create dry run:")
        print("Output: \(plan.outputURL.path)")
        for file in plan.files {
            print("create \(file.relativeDestinationPath)")
        }
        print("Planned files: \(plan.files.count)")
    } else {
        try creator.materialize(plan)
        print("FSD template created: \(plan.outputURL.path)")
        print("Created files: \(plan.files.count)")
    }
} catch let error as TemplateCreateError {
    print("error: \(error.description)")
    exit(1)
} catch {
    print("error: \(error.localizedDescription)")
    exit(1)
}
