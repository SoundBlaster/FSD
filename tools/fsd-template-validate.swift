#!/usr/bin/env swift
//
//  fsd-template-validate.swift
//  FSDDemoApp
//
//  Validates the copyable FSD iOS template package contract.
//

import Foundation

enum TemplateSeverity: String {
    case error
}

struct TemplateFinding {
    let severity: TemplateSeverity
    let path: String
    let message: String
}

struct TemplateValidationConfiguration {
    let templatePath: String
}

struct TemplateManifest {
    let values: [String: String]
    let layers: [String]
    let entrypointPaths: [String]
}

struct TemplateManifestParser {
    let source: String

    func parse() -> TemplateManifest {
        TemplateManifest(
            values: topLevelValues(),
            layers: topLevelList(named: "layers"),
            entrypointPaths: nestedListItems(under: "entrypoints")
        )
    }

    private func topLevelValues() -> [String: String] {
        var result: [String: String] = [:]

        for line in source.components(separatedBy: .newlines) {
            guard !line.hasPrefix(" "),
                  let separator = line.firstIndex(of: ":")
            else {
                continue
            }

            let key = String(line[..<separator]).trimmingCharacters(in: .whitespaces)
            let valueStart = line.index(after: separator)
            let value = String(line[valueStart...]).trimmingCharacters(in: .whitespaces)

            if !key.isEmpty, !value.isEmpty {
                result[key] = value
            }
        }

        return result
    }

    private func topLevelList(named key: String) -> [String] {
        let lines = source.components(separatedBy: .newlines)
        guard let startIndex = lines.firstIndex(where: { $0 == "\(key):" }) else {
            return []
        }

        var result: [String] = []

        for line in lines.dropFirst(startIndex + 1) {
            if isNextTopLevelKey(line) {
                break
            }

            if line.hasPrefix("  - ") {
                result.append(String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces))
            }
        }

        return result
    }

    private func nestedListItems(under key: String) -> [String] {
        let lines = source.components(separatedBy: .newlines)
        guard let startIndex = lines.firstIndex(where: { $0 == "\(key):" }) else {
            return []
        }

        var result: [String] = []

        for line in lines.dropFirst(startIndex + 1) {
            if isNextTopLevelKey(line) {
                break
            }

            if line.hasPrefix("    - ") {
                result.append(String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces))
            }
        }

        return result
    }

    private func isNextTopLevelKey(_ line: String) -> Bool {
        guard !line.isEmpty, !line.hasPrefix(" ") else {
            return false
        }

        return line.hasSuffix(":") || line.contains(":")
    }
}

struct TemplateValidator {
    private let fileManager = FileManager.default
    private let templateURL: URL

    private let expectedLayers = [
        "app",
        "pages",
        "widgets",
        "features",
        "entities",
        "shared",
    ]

    private let requiredPaths = [
        "README.md",
        "template.yaml",
        "Makefile",
        "docs/checklist.md",
        "tools/README.md",
        ".github/PULL_REQUEST_TEMPLATE.md",
        ".github/workflows/ios-ci.yml",
        "AppName/app/entrypoint/AppNameApp.swift",
        "AppName/app/providers/AppDependencies.swift",
        "AppName/pages/home/ui/HomePage.swift",
        "AppName/widgets/sample-list/ui/SampleListWidget.swift",
        "AppName/features/create-sample-item/model/CreateSampleItemAction.swift",
        "AppName/features/create-sample-item/ui/CreateSampleItemButton.swift",
        "AppName/entities/sample-item/model/SampleItem.swift",
        "AppName/entities/sample-item/ui/SampleItemRow.swift",
        "AppName/shared/ui/EmptyStateView.swift",
        "AppNameTests/AppNameTests.swift",
    ]

    init(templateURL: URL) {
        self.templateURL = templateURL
    }

    func run() -> [TemplateFinding] {
        var findings: [TemplateFinding] = []

        guard directoryExists(templateURL) else {
            return [
                error(".", "Template root does not exist or is not a directory"),
            ]
        }

        guard let manifest = loadManifest(findings: &findings) else {
            return findings
        }

        validateManifest(manifest, findings: &findings)
        validateRequiredPaths(manifest: manifest, findings: &findings)
        validateLayerDirectories(findings: &findings)
        validateMakefile(findings: &findings)
        validateWorkflow(findings: &findings)
        validatePullRequestTemplate(findings: &findings)

        return findings
    }

    private func loadManifest(findings: inout [TemplateFinding]) -> TemplateManifest? {
        let manifestURL = templateURL.appendingPathComponent("template.yaml")

        guard fileManager.fileExists(atPath: manifestURL.path) else {
            findings.append(error("template.yaml", "Template manifest is missing"))
            return nil
        }

        guard let source = try? String(contentsOf: manifestURL, encoding: .utf8) else {
            findings.append(error("template.yaml", "Template manifest cannot be read as UTF-8"))
            return nil
        }

        return TemplateManifestParser(source: source).parse()
    }

    private func validateManifest(_ manifest: TemplateManifest, findings: inout [TemplateFinding]) {
        let requiredValues = [
            "name",
            "version",
            "kind",
            "status",
            "language",
            "ui",
        ]

        for key in requiredValues where manifest.values[key] == nil {
            findings.append(error("template.yaml", "Manifest is missing top-level value `\(key)`"))
        }

        if manifest.values["kind"] != "reference-template" {
            findings.append(error("template.yaml", "Manifest `kind` must be `reference-template`"))
        }

        if manifest.layers != expectedLayers {
            findings.append(
                error(
                    "template.yaml",
                    "Manifest layers must be exactly: \(expectedLayers.joined(separator: ", "))"
                )
            )
        }

        if manifest.entrypointPaths.isEmpty {
            findings.append(error("template.yaml", "Manifest must list entrypoint paths"))
        }
    }

    private func validateRequiredPaths(
        manifest: TemplateManifest,
        findings: inout [TemplateFinding]
    ) {
        let allRequiredPaths = Set(requiredPaths).union(manifest.entrypointPaths)

        for path in allRequiredPaths.sorted() where !fileExists(path) {
            findings.append(error(path, "Required template path is missing"))
        }
    }

    private func validateLayerDirectories(findings: inout [TemplateFinding]) {
        for layer in expectedLayers {
            let path = "AppName/\(layer)"

            guard directoryExists(templateURL.appendingPathComponent(path)) else {
                findings.append(error(path, "Template source root is missing FSD layer `\(layer)`"))
                continue
            }
        }
    }

    private func validateMakefile(findings: inout [TemplateFinding]) {
        guard let source = read("Makefile", findings: &findings) else {
            return
        }

        let requiredVariables = [
            "PROJECT :=",
            "SCHEME :=",
            "APP_ROOT :=",
            "FSD_LINT ?=",
        ]

        for variable in requiredVariables where !source.contains(variable) {
            findings.append(error("Makefile", "Template Makefile is missing `\(variable)`"))
        }

        let requiredTargets = [
            "lint",
            "lint-strict",
            "lint-architecture",
            "build",
            "test",
            "demo",
            "ci",
        ]

        for target in requiredTargets where !containsMakeTarget(target, in: source) {
            findings.append(error("Makefile", "Template Makefile is missing target `\(target)`"))
        }
    }

    private func validateWorkflow(findings: inout [TemplateFinding]) {
        let path = ".github/workflows/ios-ci.yml"
        guard let source = read(path, findings: &findings) else {
            return
        }

        if !source.contains("make build SIMULATOR=") {
            findings.append(error(path, "Template CI should delegate build to `make build`"))
        }

        if !source.contains("make test SIMULATOR=") {
            findings.append(error(path, "Template CI should delegate tests to `make test`"))
        }

        if source.contains("-project AppName.xcodeproj") || source.contains("-scheme AppName") {
            findings.append(error(path, "Template CI should not hardcode placeholder project or scheme names"))
        }
    }

    private func validatePullRequestTemplate(findings: inout [TemplateFinding]) {
        let path = ".github/PULL_REQUEST_TEMPLATE.md"
        guard let source = read(path, findings: &findings) else {
            return
        }

        let requiredSections = [
            "## Goals",
            "## Motivation",
            "## What Changed",
            "## Validation",
            "## FSD Checklist",
            "## Notes",
        ]

        for section in requiredSections where !source.contains(section) {
            findings.append(error(path, "PR template is missing section `\(section)`"))
        }
    }

    private func containsMakeTarget(_ target: String, in source: String) -> Bool {
        source.components(separatedBy: .newlines).contains { line in
            line == "\(target):" || line.hasPrefix("\(target): ")
        }
    }

    private func read(_ path: String, findings: inout [TemplateFinding]) -> String? {
        let url = templateURL.appendingPathComponent(path)

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        guard let source = try? String(contentsOf: url, encoding: .utf8) else {
            findings.append(error(path, "Required template file cannot be read as UTF-8"))
            return nil
        }

        return source
    }

    private func fileExists(_ path: String) -> Bool {
        fileManager.fileExists(atPath: templateURL.appendingPathComponent(path).path)
    }

    private func directoryExists(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private func error(_ path: String, _ message: String) -> TemplateFinding {
        TemplateFinding(severity: .error, path: path, message: message)
    }
}

func parseTemplateValidationArguments(_ arguments: [String]) -> TemplateValidationConfiguration? {
    var templatePath = "templates/fsd-ios"
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--help", "-h":
            printTemplateValidationUsage()
            return nil
        case "--template":
            index += 1
            guard index < arguments.count else {
                print("error: --template requires a path")
                exit(2)
            }
            templatePath = arguments[index]
        default:
            if argument.hasPrefix("-") {
                print("error: unknown option \(argument)")
                exit(2)
            }
            templatePath = argument
        }

        index += 1
    }

    return TemplateValidationConfiguration(templatePath: templatePath)
}

func printTemplateValidationUsage() {
    print(
        """
        Usage:
          swift tools/fsd-template-validate.swift [--template <path>]
          swift tools/fsd-template-validate.swift templates/fsd-ios

        Checks the copyable FSD iOS template package contract:
          - manifest has required metadata and canonical FSD layers
          - manifest entrypoints exist
          - template source root contains required layers and sample files
          - template Makefile exposes expected local workflow targets
          - template CI delegates build/test to Makefile variables
          - PR template contains required review sections

        Options:
          --template <path>  Template package root. Defaults to `templates/fsd-ios`.
        """
    )
}

func makeTemplateURL(from path: String) -> URL {
    if path.hasPrefix("/") {
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(path)
        .standardizedFileURL
}

guard let configuration = parseTemplateValidationArguments(Array(CommandLine.arguments.dropFirst())) else {
    exit(0)
}

let templateURL = makeTemplateURL(from: configuration.templatePath)
let findings = TemplateValidator(templateURL: templateURL).run()

for finding in findings {
    print("\(finding.severity.rawValue): \(finding.path): \(finding.message)")
}

if findings.isEmpty {
    print("FSD template validation passed: 0 errors")
} else {
    print("FSD template validation failed: \(findings.count) errors")
}

exit(findings.isEmpty ? 0 : 1)
