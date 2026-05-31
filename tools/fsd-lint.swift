#!/usr/bin/env swift
//
//  fsd-lint.swift
//  FSDDemoApp
//
//  Baseline Feature-Sliced Design structure linter for Swift projects.
//

import Foundation

#if os(Linux)
import Glibc
#else
import Darwin
#endif

enum Severity: String {
    case error
    case warning
}

enum ReportFormat: String {
    case text
    case json
    case xcode
    case sarif
}

struct Finding {
    let ruleId: String
    let severity: Severity
    let path: String
    let absolutePath: String
    let line: Int?
    let message: String
    let suggestion: String?
}

struct LayerConfiguration {
    var app: String
    var pages: String
    var widgets: String
    var features: String
    var entities: String
    var shared: String

    static let defaults = LayerConfiguration(
        app: "app",
        pages: "pages",
        widgets: "widgets",
        features: "features",
        entities: "entities",
        shared: "shared"
    )

    var all: Set<String> {
        [app, pages, widgets, features, entities, shared]
    }

    var sliced: Set<String> {
        [pages, widgets, features, entities]
    }

    var sameLayerSliceIsolation: Set<String> {
        [widgets, features, entities]
    }

    var ranks: [String: Int] {
        [
            shared: 0,
            entities: 1,
            features: 2,
            widgets: 3,
            pages: 4,
            app: 5,
        ]
    }

    mutating func apply(key: String, value: String) throws {
        switch key {
        case "app":
            app = value
        case "pages":
            pages = value
        case "widgets":
            widgets = value
        case "features":
            features = value
        case "entities":
            entities = value
        case "shared":
            shared = value
        default:
            throw ConfigError.invalidValue("layers.\(key)", "Unknown layer key")
        }
    }

    func validated() throws -> LayerConfiguration {
        let values = [app, pages, widgets, features, entities, shared]

        for value in values {
            guard !value.isEmpty else {
                throw ConfigError.invalidValue("layers", "Layer folder names must not be empty")
            }

            guard !value.contains("/") else {
                throw ConfigError.invalidValue("layers", "Layer folder name `\(value)` must not contain `/`")
            }
        }

        guard Set(values).count == values.count else {
            throw ConfigError.invalidValue("layers", "Layer folder names must be unique")
        }

        return self
    }
}

struct RuleConfiguration {
    var rootStructure: Bool
    var layerSegments: Bool
    var sliceSegments: Bool
    var dependencyDirection: Bool
    var sameLayerSliceIsolation: Bool

    static let defaults = RuleConfiguration(
        rootStructure: true,
        layerSegments: true,
        sliceSegments: true,
        dependencyDirection: true,
        sameLayerSliceIsolation: true
    )

    mutating func apply(key: String, value: Bool) throws {
        switch key {
        case "rootStructure":
            rootStructure = value
        case "layerSegments":
            layerSegments = value
        case "sliceSegments":
            sliceSegments = value
        case "dependencyDirection":
            dependencyDirection = value
        case "sameLayerSliceIsolation":
            sameLayerSliceIsolation = value
        default:
            throw ConfigError.invalidValue("rules.\(key)", "Unknown rule key")
        }
    }
}

struct Configuration {
    let rootPath: String
    let reportRootPath: String?
    let strict: Bool
    let architecture: Bool
    let format: ReportFormat
    let ignoredPaths: [String]
    let layers: LayerConfiguration
    let rules: RuleConfiguration
}

struct ArgumentConfiguration {
    let rootPath: String?
    let reportRootPath: String?
    let strict: Bool?
    let architecture: Bool?
    let format: ReportFormat?
    let configPath: String?
}

struct FileConfiguration {
    let url: URL
    let rootPath: String?
    let strict: Bool?
    let architecture: Bool?
    let ignoredPaths: [String]
    let layers: LayerConfiguration
    let rules: RuleConfiguration
}

struct ConfigLine {
    let number: Int
    let indent: Int
    let content: String
}

enum ConfigError: Error, CustomStringConvertible {
    case readFailed(String)
    case syntax(line: Int, message: String)
    case invalidValue(String, String)

    var description: String {
        switch self {
        case .readFailed(let message):
            return message
        case .syntax(let line, let message):
            return "line \(line): \(message)"
        case .invalidValue(let key, let message):
            return "\(key): \(message)"
        }
    }
}

struct FSDLinter {
    private let fileManager = FileManager.default
    private let rootURL: URL
    private let strict: Bool
    private let architectureChecksEnabled: Bool
    private let ignoredPaths: [String]
    private let layerConfiguration: LayerConfiguration
    private let rules: RuleConfiguration

    private var layers: Set<String> {
        layerConfiguration.all
    }

    private var slicedLayers: Set<String> {
        layerConfiguration.sliced
    }

    private let appSegments: Set<String> = [
        "config",
        "entrypoint",
        "providers",
        "routes",
        "styles",
    ]

    private let sharedSegments: Set<String> = [
        "api",
        "assets",
        "config",
        "lib",
        "testing",
        "ui",
    ]

    private let sliceSegments: Set<String> = [
        "api",
        "assets",
        "config",
        "lib",
        "model",
        "testing",
        "ui",
    ]

    private let allowedRootDirectories: Set<String> = [
        "Assets.xcassets",
        "Preview Content",
    ]

    private var layerRanks: [String: Int] {
        layerConfiguration.ranks
    }

    private var sameLayerSliceIsolationLayers: Set<String> {
        layerConfiguration.sameLayerSliceIsolation
    }

    private let swiftKeywords: Set<String> = [
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

    init(
        rootURL: URL,
        strict: Bool,
        architectureChecksEnabled: Bool,
        ignoredPaths: [String],
        layerConfiguration: LayerConfiguration,
        rules: RuleConfiguration
    ) {
        self.rootURL = rootURL
        self.strict = strict
        self.architectureChecksEnabled = architectureChecksEnabled
        self.ignoredPaths = ignoredPaths.map(Self.normalizeIgnoredPath)
        self.layerConfiguration = layerConfiguration
        self.rules = rules
    }

    func run() -> [Finding] {
        var findings: [Finding] = []

        guard directoryExists(rootURL) else {
            return [
                Finding(
                    ruleId: "fsd/root-missing",
                    severity: .error,
                    path: rootURL.path,
                    absolutePath: rootURL.path,
                    line: nil,
                    message: "FSD root does not exist or is not a directory",
                    suggestion: "Pass --root with an existing FSD source directory."
                ),
            ]
        }

        if rules.rootStructure {
            lintRoot(&findings)
        }

        if rules.sliceSegments {
            lintSlicedLayers(&findings)
        }

        if rules.layerSegments {
            lintSlicelessLayers(&findings)
        }

        if architectureChecksEnabled {
            lintArchitectureDependencies(&findings)
        }

        return findings
    }

    private func lintRoot(_ findings: inout [Finding]) {
        let directories = childDirectories(of: rootURL)

        for directory in directories {
            let name = directory.lastPathComponent

            if name == "processes" {
                findings.append(
                    error(
                        directory,
                        ruleId: "fsd/deprecated-processes-layer",
                        "Deprecated FSD layer `processes` should not be used",
                        suggestion: "Move process orchestration to pages, widgets, features, or app composition."
                    )
                )
                continue
            }

            guard !layers.contains(name), !allowedRootDirectories.contains(name) else {
                continue
            }

            findings.append(
                warning(
                    directory,
                    ruleId: "fsd/unknown-root-directory",
                    "Directory is outside known FSD layers",
                    suggestion: "Move the directory under a configured FSD layer or add it to ignoredPaths."
                )
            )
        }

        for file in childFiles(of: rootURL) where file.pathExtension == "swift" {
            findings.append(
                error(
                    file,
                    ruleId: "fsd/root-swift-file",
                    "Swift files should live inside an FSD layer",
                    suggestion: "Move the file under app, pages, widgets, features, entities, or shared."
                )
            )
        }
    }

    private func lintSlicedLayers(_ findings: inout [Finding]) {
        for layer in slicedLayers.sorted() {
            let layerURL = rootURL.appendingPathComponent(layer)

            guard directoryExists(layerURL) else {
                continue
            }

            for file in childFiles(of: layerURL) where file.pathExtension == "swift" {
                findings.append(
                    error(
                        file,
                        ruleId: "fsd/sliced-layer-file",
                        "Swift files in sliced layers should live inside a slice segment",
                        suggestion: "Create a slice and segment path such as \(layer)/<slice>/ui."
                    )
                )
            }

            for sliceURL in childDirectories(of: layerURL) {
                lintSlice(sliceURL, layer: layer, findings: &findings)
            }
        }
    }

    private func lintSlice(_ sliceURL: URL, layer: String, findings: inout [Finding]) {
        let sliceName = sliceURL.lastPathComponent

        if sliceSegments.contains(sliceName) {
            findings.append(
                error(
                    sliceURL,
                    ruleId: "fsd/slice-name-looks-like-segment",
                    "Sliced layer `\(layer)` must contain slices first; `\(sliceName)` looks like a segment",
                    suggestion: "Insert a business slice name between the layer and segment."
                )
            )
        }

        let segmentURLs = childDirectories(of: sliceURL)

        if segmentURLs.isEmpty {
            findings.append(
                error(
                    sliceURL,
                    ruleId: "fsd/slice-missing-segments",
                    "Slice has no segments such as `ui`, `model`, `api`, or `lib`",
                    suggestion: "Add at least one purpose segment, for example ui or model."
                )
            )
        }

        for file in childFiles(of: sliceURL) where file.pathExtension == "swift" {
            findings.append(
                error(
                    file,
                    ruleId: "fsd/slice-root-swift-file",
                    "Swift files should live inside a segment, not directly in a slice",
                    suggestion: "Move the file into a segment such as ui, model, api, or lib."
                )
            )
        }

        for segmentURL in segmentURLs {
            let segmentName = segmentURL.lastPathComponent

            if !sliceSegments.contains(segmentName) {
                findings.append(
                    warning(
                        segmentURL,
                        ruleId: "fsd/unexpected-slice-segment",
                        "Unexpected segment `\(segmentName)` in `\(layer)/\(sliceName)`",
                        suggestion: "Rename the directory to an allowed segment or add it to ignoredPaths."
                    )
                )
            }

            lintReservedNestedSegments(in: segmentURL, findings: &findings)
        }
    }

    private func lintSlicelessLayers(_ findings: inout [Finding]) {
        lintSlicelessLayer(
            name: layerConfiguration.app,
            allowedSegments: appSegments,
            findings: &findings
        )

        lintSlicelessLayer(
            name: layerConfiguration.shared,
            allowedSegments: sharedSegments,
            findings: &findings
        )
    }

    private func lintSlicelessLayer(
        name: String,
        allowedSegments: Set<String>,
        findings: inout [Finding]
    ) {
        let layerURL = rootURL.appendingPathComponent(name)

        guard directoryExists(layerURL) else {
            return
        }

        for file in childFiles(of: layerURL) where file.pathExtension == "swift" {
            findings.append(
                warning(
                    file,
                    ruleId: "fsd/sliceless-layer-file",
                    "Consider moving Swift files into a purpose segment",
                    suggestion: "Move the file into an allowed segment such as ui, lib, config, providers, or routes."
                )
            )
        }

        for segmentURL in childDirectories(of: layerURL) {
            let segmentName = segmentURL.lastPathComponent

            if name == layerConfiguration.app, segmentName == "ui" {
                let uiOwnerLayers = [
                    layerConfiguration.pages,
                    layerConfiguration.widgets,
                    layerConfiguration.features,
                    layerConfiguration.entities,
                    layerConfiguration.shared,
                ]
                .map { "`\($0)`" }
                .joined(separator: ", ")

                findings.append(
                    error(
                        segmentURL,
                        ruleId: "fsd/app-ui-segment",
                        "`\(layerConfiguration.app)/ui` is discouraged; UI should usually live in configured UI-owning layers: \(uiOwnerLayers)",
                        suggestion: "Move screen or reusable UI into pages, widgets, features, entities, or shared/ui."
                    )
                )
                continue
            }

            if layers.contains(segmentName) {
                findings.append(
                    error(
                        segmentURL,
                        ruleId: "fsd/nested-layer-name",
                        "FSD layer name `\(segmentName)` should not be nested inside `\(name)`",
                        suggestion: "Keep FSD layers at the source root."
                    )
                )
                continue
            }

            if !allowedSegments.contains(segmentName) {
                findings.append(
                    warning(
                        segmentURL,
                        ruleId: "fsd/unexpected-layer-segment",
                        "Unexpected segment `\(segmentName)` in `\(name)` layer",
                        suggestion: "Rename the directory to an allowed segment or add it to ignoredPaths."
                    )
                )
            }
        }
    }

    private func lintReservedNestedSegments(in segmentURL: URL, findings: inout [Finding]) {
        for directory in childDirectories(of: segmentURL) {
            let name = directory.lastPathComponent

            guard sliceSegments.contains(name) else {
                continue
            }

            findings.append(
                warning(
                    directory,
                    ruleId: "fsd/nested-reserved-segment",
                    "Nested directory reuses reserved segment name `\(name)`",
                    suggestion: "Use a domain-specific nested folder name instead of an FSD segment name."
                )
            )
        }
    }

    private func lintArchitectureDependencies(_ findings: inout [Finding]) {
        let files = swiftFiles(under: rootURL).compactMap(makeSourceFile)
        let ownersBySymbol = Dictionary(
            grouping: files.flatMap { file in
                file.declarations.map { SymbolOwner(symbol: $0, file: file) }
            },
            by: \.symbol
        )
        var emittedFindings: Set<String> = []

        for sourceFile in files {
            for reference in sourceFile.references.sorted() {
                guard !sourceFile.declarations.contains(reference),
                      let owners = ownersBySymbol[reference],
                      owners.count == 1,
                      let targetFile = owners.first?.file,
                      sourceFile.relativePath != targetFile.relativePath,
                      let violation = dependencyViolation(
                        from: sourceFile,
                        to: targetFile,
                        symbol: reference
                      )
                else {
                    continue
                }

                let key = "\(sourceFile.relativePath)|\(targetFile.relativePath)|\(reference)|\(violation.ruleId)|\(violation.message)"

                guard !emittedFindings.contains(key) else {
                    continue
                }

                emittedFindings.insert(key)
                findings.append(
                    error(
                        sourceFile.url,
                        ruleId: violation.ruleId,
                        violation.message,
                        suggestion: violation.suggestion
                    )
                )
            }
        }
    }

    private func dependencyViolation(
        from sourceFile: SourceFile,
        to targetFile: SourceFile,
        symbol: String
    ) -> DependencyViolation? {
        guard let sourceLayer = sourceFile.layer,
              let targetLayer = targetFile.layer,
              let sourceRank = layerRanks[sourceLayer],
              let targetRank = layerRanks[targetLayer]
        else {
            return nil
        }

        if sourceLayer == targetLayer {
            guard rules.sameLayerSliceIsolation else {
                return nil
            }

            guard sameLayerSliceIsolationLayers.contains(sourceLayer),
                  sourceFile.slice != nil,
                  targetFile.slice != nil,
                  sourceFile.slice != targetFile.slice
            else {
                return nil
            }

            return DependencyViolation(
                ruleId: "fsd/same-layer-slice-dependency",
                message: "Same-layer slices should not depend on each other: `\(sourceLayer)/\(sourceFile.slice ?? "")` references `\(symbol)` from `\(targetLayer)/\(targetFile.slice ?? "")`",
                suggestion: "Move shared behavior to a lower layer or compose both slices from a higher layer."
            )
        }

        guard rules.dependencyDirection else {
            return nil
        }

        guard sourceRank < targetRank else {
            return nil
        }

        return DependencyViolation(
            ruleId: "fsd/dependency-direction",
            message: "Invalid FSD dependency direction: `\(sourceLayer)` references `\(symbol)` from higher layer `\(targetLayer)`",
            suggestion: "Invert the dependency or move shared behavior to a lower FSD layer."
        )
    }

    private func childDirectories(of url: URL) -> [URL] {
        children(of: url).filter(directoryExists)
    }

    private func childFiles(of url: URL) -> [URL] {
        children(of: url).filter { !directoryExists($0) }
    }

    private func children(of url: URL) -> [URL] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { !isIgnored($0) }
            .sorted { $0.path < $1.path }
    }

    private func directoryExists(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private func swiftFiles(under url: URL) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item -> URL? in
            guard let url = item as? URL else {
                return nil
            }

            if directoryExists(url), isIgnored(url) {
                enumerator.skipDescendants()
                return nil
            }

            guard url.pathExtension == "swift", !isIgnored(url) else {
                return nil
            }

            return url
        }
        .sorted { $0.path < $1.path }
    }

    private func makeSourceFile(from url: URL) -> SourceFile? {
        guard let source = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let relativePath = relativePath(for: url)
        let parts = relativePath.split(separator: "/").map(String.init)
        let layer = parts.first.flatMap { layers.contains($0) ? $0 : nil }
        let slice: String?
        let segment: String?

        if let layer, slicedLayers.contains(layer) {
            slice = parts.count > 1 ? parts[1] : nil
            segment = parts.count > 2 ? parts[2] : nil
        } else {
            slice = nil
            segment = parts.count > 1 ? parts[1] : nil
        }

        let strippedSource = stripCommentsAndStringLiterals(from: source)
        let declarations = Set(captureDeclarations(in: strippedSource))
        let references = Set(captureIdentifiers(in: strippedSource))
            .subtracting(swiftKeywords)

        return SourceFile(
            url: url,
            relativePath: relativePath,
            layer: layer,
            slice: slice,
            segment: segment,
            declarations: declarations,
            references: references
        )
    }

    private func captureDeclarations(in source: String) -> [String] {
        captureGroups(
            pattern: #"\b(?:struct|class|enum|protocol|actor|typealias)\s+([A-Za-z_][A-Za-z0-9_]*)"#,
            in: source
        )
    }

    private func captureIdentifiers(in source: String) -> [String] {
        captureMatches(
            pattern: #"\b[A-Za-z_][A-Za-z0-9_]*\b"#,
            in: source
        )
    }

    private func captureGroups(pattern: String, in source: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        return regex.matches(in: source, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: source)
            else {
                return nil
            }

            return String(source[range])
        }
    }

    private func captureMatches(pattern: String, in source: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        return regex.matches(in: source, range: range).compactMap { match in
            guard let range = Range(match.range, in: source) else {
                return nil
            }

            return String(source[range])
        }
    }

    private func stripCommentsAndStringLiterals(from source: String) -> String {
        var result = ""
        var index = source.startIndex
        var blockCommentDepth = 0
        var isInLineComment = false
        var isInString = false
        var isEscaped = false

        func nextCharacter(after current: String.Index) -> Character? {
            let nextIndex = source.index(after: current)
            guard nextIndex < source.endIndex else {
                return nil
            }
            return source[nextIndex]
        }

        func interpolationEnd(openingParen: String.Index) -> String.Index? {
            var cursor = source.index(after: openingParen)
            var parenthesisDepth = 1
            var nestedBlockCommentDepth = 0
            var isInNestedLineComment = false
            var isInNestedString = false
            var isNestedEscaped = false

            while cursor < source.endIndex {
                let character = source[cursor]
                let nextCharacter = nextCharacter(after: cursor)

                if isInNestedLineComment {
                    if character == "\n" {
                        isInNestedLineComment = false
                    }
                    cursor = source.index(after: cursor)
                    continue
                }

                if nestedBlockCommentDepth > 0 {
                    if character == "/", nextCharacter == "*" {
                        nestedBlockCommentDepth += 1
                        cursor = source.index(cursor, offsetBy: 2)
                    } else if character == "*", nextCharacter == "/" {
                        nestedBlockCommentDepth -= 1
                        cursor = source.index(cursor, offsetBy: 2)
                    } else {
                        cursor = source.index(after: cursor)
                    }
                    continue
                }

                if isInNestedString {
                    if isNestedEscaped {
                        isNestedEscaped = false
                    } else if character == "\\", nextCharacter == "(" {
                        let nestedOpeningParen = source.index(after: cursor)
                        if let nestedEnd = interpolationEnd(openingParen: nestedOpeningParen) {
                            cursor = source.index(after: nestedEnd)
                            continue
                        }
                        isNestedEscaped = true
                    } else if character == "\\" {
                        isNestedEscaped = true
                    } else if character == "\"" {
                        isInNestedString = false
                    }

                    cursor = source.index(after: cursor)
                    continue
                }

                if character == "/", nextCharacter == "/" {
                    isInNestedLineComment = true
                    cursor = source.index(cursor, offsetBy: 2)
                    continue
                }

                if character == "/", nextCharacter == "*" {
                    nestedBlockCommentDepth = 1
                    cursor = source.index(cursor, offsetBy: 2)
                    continue
                }

                if character == "\"" {
                    isInNestedString = true
                    cursor = source.index(after: cursor)
                    continue
                }

                if character == "(" {
                    parenthesisDepth += 1
                } else if character == ")" {
                    parenthesisDepth -= 1

                    if parenthesisDepth == 0 {
                        return cursor
                    }
                }

                cursor = source.index(after: cursor)
            }

            return nil
        }

        while index < source.endIndex {
            let character = source[index]
            let nextCharacter = nextCharacter(after: index)

            if isInLineComment {
                if character == "\n" {
                    isInLineComment = false
                    result.append(character)
                } else {
                    result.append(" ")
                }
                index = source.index(after: index)
                continue
            }

            if blockCommentDepth > 0 {
                if character == "/", nextCharacter == "*" {
                    blockCommentDepth += 1
                    result.append(" ")
                    result.append(" ")
                    index = source.index(index, offsetBy: 2)
                } else if character == "*", nextCharacter == "/" {
                    blockCommentDepth -= 1
                    result.append(" ")
                    result.append(" ")
                    index = source.index(index, offsetBy: 2)
                } else {
                    result.append(character == "\n" ? "\n" : " ")
                    index = source.index(after: index)
                }
                continue
            }

            if isInString {
                if isEscaped {
                    isEscaped = false
                    result.append(" ")
                } else if character == "\\", nextCharacter == "(" {
                    let openingParen = source.index(after: index)

                    if let end = interpolationEnd(openingParen: openingParen) {
                        result.append(" ")
                        result.append(" ")

                        let expressionStart = source.index(after: openingParen)
                        if expressionStart < end {
                            let expression = String(source[expressionStart..<end])
                            result.append(stripCommentsAndStringLiterals(from: expression))
                        }

                        result.append(" ")
                        index = source.index(after: end)
                        continue
                    }

                    isEscaped = true
                    result.append(" ")
                } else if character == "\\" {
                    isEscaped = true
                    result.append(" ")
                } else if character == "\"" {
                    isInString = false
                    result.append(" ")
                } else {
                    result.append(character == "\n" ? "\n" : " ")
                }
                index = source.index(after: index)
                continue
            }

            if character == "/", nextCharacter == "/" {
                isInLineComment = true
                result.append(" ")
                result.append(" ")
                index = source.index(index, offsetBy: 2)
                continue
            }

            if character == "/", nextCharacter == "*" {
                blockCommentDepth = 1
                result.append(" ")
                result.append(" ")
                index = source.index(index, offsetBy: 2)
                continue
            }

            if character == "\"" {
                isInString = true
                result.append(" ")
                index = source.index(after: index)
                continue
            }

            result.append(character)
            index = source.index(after: index)
        }

        return result
    }

    private func error(
        _ url: URL,
        ruleId: String,
        _ message: String,
        suggestion: String? = nil
    ) -> Finding {
        Finding(
            ruleId: ruleId,
            severity: .error,
            path: relativePath(for: url),
            absolutePath: url.standardizedFileURL.path,
            line: nil,
            message: message,
            suggestion: suggestion
        )
    }

    private func warning(
        _ url: URL,
        ruleId: String,
        _ message: String,
        suggestion: String? = nil
    ) -> Finding {
        Finding(
            ruleId: ruleId,
            severity: strict ? .error : .warning,
            path: relativePath(for: url),
            absolutePath: url.standardizedFileURL.path,
            line: nil,
            message: message,
            suggestion: suggestion
        )
    }

    private func relativePath(for url: URL) -> String {
        let rootPath = rootURL.path
        let path = url.standardizedFileURL.path

        guard path.hasPrefix(rootPath) else {
            return path
        }

        let startIndex = path.index(path.startIndex, offsetBy: rootPath.count)
        let relative = String(path[startIndex...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return relative.isEmpty ? "." : relative
    }

    private func isIgnored(_ url: URL) -> Bool {
        guard !ignoredPaths.isEmpty else {
            return false
        }

        let relativePath = Self.normalizeIgnoredPath(relativePath(for: url))

        return ignoredPaths.contains { ignoredPath in
            relativePath == ignoredPath || relativePath.hasPrefix("\(ignoredPath)/")
        }
    }

    private static func normalizeIgnoredPath(_ path: String) -> String {
        path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private struct SourceFile {
        let url: URL
        let relativePath: String
        let layer: String?
        let slice: String?
        let segment: String?
        let declarations: Set<String>
        let references: Set<String>
    }

    private struct SymbolOwner {
        let symbol: String
        let file: SourceFile
    }

    private struct DependencyViolation {
        let ruleId: String
        let message: String
        let suggestion: String
    }
}

func parseArguments(_ arguments: [String]) -> ArgumentConfiguration? {
    var rootPath: String?
    var reportRootPath: String?
    var strict: Bool?
    var architecture: Bool?
    var format: ReportFormat?
    var configPath: String?
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--help", "-h":
            printUsage()
            return nil
        case "--strict":
            strict = true
        case "--no-strict":
            strict = false
        case "--architecture":
            architecture = true
        case "--no-architecture":
            architecture = false
        case "--format":
            index += 1
            guard index < arguments.count, !arguments[index].hasPrefix("-") else {
                print("error: --format requires one of: text, json, xcode, sarif")
                exit(2)
            }
            guard let parsedFormat = ReportFormat(rawValue: arguments[index]) else {
                print("error: unsupported --format `\(arguments[index])`; expected one of: text, json, xcode, sarif")
                exit(2)
            }
            format = parsedFormat
        case "--root":
            index += 1
            guard index < arguments.count else {
                print("error: --root requires a path")
                exit(2)
            }
            rootPath = arguments[index]
        case "--report-root":
            index += 1
            guard index < arguments.count else {
                print("error: --report-root requires a path")
                exit(2)
            }
            reportRootPath = arguments[index]
        case "--config":
            index += 1
            guard index < arguments.count else {
                print("error: --config requires a path")
                exit(2)
            }
            configPath = arguments[index]
        default:
            if argument.hasPrefix("-") {
                print("error: unknown option \(argument)")
                exit(2)
            }
            rootPath = argument
        }

        index += 1
    }

    return ArgumentConfiguration(
        rootPath: rootPath,
        reportRootPath: reportRootPath,
        strict: strict,
        architecture: architecture,
        format: format,
        configPath: configPath
    )
}

func makeConfiguration(from arguments: ArgumentConfiguration) throws -> Configuration {
    let fileConfiguration = try loadFileConfiguration(from: arguments.configPath)

    let rootPath: String

    if let argumentRootPath = arguments.rootPath {
        rootPath = makeURL(from: argumentRootPath).path
    } else if let configRootPath = fileConfiguration?.rootPath {
        rootPath = makeURL(
            from: configRootPath,
            relativeTo: fileConfiguration?.url.deletingLastPathComponent() ?? currentDirectoryURL()
        ).path
    } else {
        rootPath = makeURL(from: "FSDDemoApp").path
    }

    return Configuration(
        rootPath: rootPath,
        reportRootPath: arguments.reportRootPath.map { makeURL(from: $0).path },
        strict: arguments.strict ?? fileConfiguration?.strict ?? false,
        architecture: arguments.architecture ?? fileConfiguration?.architecture ?? false,
        format: arguments.format ?? .text,
        ignoredPaths: fileConfiguration?.ignoredPaths ?? [],
        layers: try (fileConfiguration?.layers ?? .defaults).validated(),
        rules: fileConfiguration?.rules ?? .defaults
    )
}

func loadFileConfiguration(from path: String?) throws -> FileConfiguration? {
    if let path {
        let url = makeURL(from: path)

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ConfigError.readFailed("Config file does not exist: \(url.path)")
        }

        return try parseFileConfiguration(at: url)
    }

    guard let discoveredURL = discoverDefaultConfigURL() else {
        return nil
    }

    return try parseFileConfiguration(at: discoveredURL)
}

func discoverDefaultConfigURL() -> URL? {
    let directory = currentDirectoryURL()

    for filename in [".fsd-ios.yml", ".fsd-ios.yaml"] {
        let url = directory.appendingPathComponent(filename).standardizedFileURL

        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
    }

    return nil
}

func parseFileConfiguration(at url: URL) throws -> FileConfiguration {
    let source: String

    do {
        source = try String(contentsOf: url, encoding: .utf8)
    } catch {
        throw ConfigError.readFailed("Could not read config file: \(url.path)")
    }

    let lines = try parseConfigLines(source)
    var rootPath: String?
    var strict: Bool?
    var architecture: Bool?
    var ignoredPaths: [String] = []
    var layers = LayerConfiguration.defaults
    var rules = RuleConfiguration.defaults
    var index = 0

    while index < lines.count {
        let line = lines[index]

        guard line.indent == 0 else {
            throw ConfigError.syntax(line: line.number, message: "Top-level keys must not be indented")
        }

        let pair = try parseKeyValue(line.content, lineNumber: line.number)

        switch pair.key {
        case "version":
            guard let value = pair.value else {
                throw ConfigError.syntax(line: line.number, message: "`version` requires a scalar value")
            }

            guard value == "1" else {
                throw ConfigError.invalidValue("version", "Only config version `1` is supported")
            }
        case "root":
            rootPath = try parseString(pair.value, key: "root", lineNumber: line.number)
        case "strict":
            strict = try parseBool(pair.value, key: "strict", lineNumber: line.number)
        case "architecture":
            architecture = try parseBool(pair.value, key: "architecture", lineNumber: line.number)
        case "ignoredPaths", "ignore":
            if let value = pair.value {
                ignoredPaths = try parseInlineList(value, key: pair.key, lineNumber: line.number)
            } else {
                index += 1
                ignoredPaths = try parseList(lines: lines, index: &index, parentIndent: line.indent, key: pair.key)
                continue
            }
        case "layers":
            guard pair.value == nil else {
                throw ConfigError.syntax(line: line.number, message: "`layers` must be a mapping")
            }

            index += 1
            let values = try parseMap(lines: lines, index: &index, parentIndent: line.indent, key: "layers")

            for value in values {
                try layers.apply(key: value.key, value: value.value)
            }

            continue
        case "rules":
            guard pair.value == nil else {
                throw ConfigError.syntax(line: line.number, message: "`rules` must be a mapping")
            }

            index += 1
            let values = try parseMap(lines: lines, index: &index, parentIndent: line.indent, key: "rules")

            for value in values {
                try rules.apply(
                    key: value.key,
                    value: parseBoolValue(value.value, key: "rules.\(value.key)", lineNumber: value.line)
                )
            }

            continue
        default:
            throw ConfigError.syntax(line: line.number, message: "Unknown config key `\(pair.key)`")
        }

        index += 1
    }

    return FileConfiguration(
        url: url,
        rootPath: rootPath,
        strict: strict,
        architecture: architecture,
        ignoredPaths: ignoredPaths,
        layers: try layers.validated(),
        rules: rules
    )
}

func parseConfigLines(_ source: String) throws -> [ConfigLine] {
    try source
        .replacingOccurrences(of: "\r\n", with: "\n")
        .split(separator: "\n", omittingEmptySubsequences: false)
        .enumerated()
        .compactMap { offset, rawLine -> ConfigLine? in
            let lineNumber = offset + 1
            let line = String(rawLine)

            guard !line.contains("\t") else {
                throw ConfigError.syntax(line: lineNumber, message: "Tabs are not supported in config indentation")
            }

            let uncommented = stripComment(from: line)
            let trimmed = uncommented.trimmingCharacters(in: .whitespaces)

            guard !trimmed.isEmpty else {
                return nil
            }

            let indent = uncommented.prefix { $0 == " " }.count
            return ConfigLine(number: lineNumber, indent: indent, content: trimmed)
        }
}

func stripComment(from line: String) -> String {
    var result = ""
    var isInSingleQuote = false
    var isInDoubleQuote = false

    for character in line {
        if character == "'", !isInDoubleQuote {
            isInSingleQuote.toggle()
        } else if character == "\"", !isInSingleQuote {
            isInDoubleQuote.toggle()
        } else if character == "#", !isInSingleQuote, !isInDoubleQuote {
            break
        }

        result.append(character)
    }

    return result
}

func parseKeyValue(_ content: String, lineNumber: Int) throws -> (key: String, value: String?) {
    guard let separatorIndex = content.firstIndex(of: ":") else {
        throw ConfigError.syntax(line: lineNumber, message: "Expected `key: value`")
    }

    let key = String(content[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
    let rawValue = String(content[content.index(after: separatorIndex)...])
        .trimmingCharacters(in: .whitespaces)

    guard !key.isEmpty else {
        throw ConfigError.syntax(line: lineNumber, message: "Config key must not be empty")
    }

    return (key, rawValue.isEmpty ? nil : rawValue)
}

func parseString(_ value: String?, key: String, lineNumber: Int) throws -> String {
    guard let value else {
        throw ConfigError.syntax(line: lineNumber, message: "`\(key)` requires a scalar value")
    }

    return unquote(value)
}

func parseBool(_ value: String?, key: String, lineNumber: Int) throws -> Bool {
    guard let value else {
        throw ConfigError.syntax(line: lineNumber, message: "`\(key)` requires `true` or `false`")
    }

    return try parseBoolValue(value, key: key, lineNumber: lineNumber)
}

func parseBoolValue(_ value: String, key: String, lineNumber: Int) throws -> Bool {
    switch unquote(value) {
    case "true":
        return true
    case "false":
        return false
    default:
        throw ConfigError.syntax(line: lineNumber, message: "`\(key)` must be `true` or `false`")
    }
}

func parseInlineList(_ value: String, key: String, lineNumber: Int) throws -> [String] {
    let trimmed = value.trimmingCharacters(in: .whitespaces)

    guard trimmed.hasPrefix("["), trimmed.hasSuffix("]") else {
        throw ConfigError.syntax(line: lineNumber, message: "`\(key)` must be a block list or inline list")
    }

    let body = trimmed.dropFirst().dropLast()

    guard !body.trimmingCharacters(in: .whitespaces).isEmpty else {
        return []
    }

    return body
        .split(separator: ",")
        .map { unquote(String($0).trimmingCharacters(in: .whitespaces)) }
}

func parseList(
    lines: [ConfigLine],
    index: inout Int,
    parentIndent: Int,
    key: String
) throws -> [String] {
    var values: [String] = []

    while index < lines.count {
        let line = lines[index]

        guard line.indent > parentIndent else {
            break
        }

        guard line.indent == parentIndent + 2 else {
            throw ConfigError.syntax(line: line.number, message: "`\(key)` supports one indentation level")
        }

        guard line.content.hasPrefix("- ") else {
            throw ConfigError.syntax(line: line.number, message: "`\(key)` entries must use `- value`")
        }

        let value = String(line.content.dropFirst(2)).trimmingCharacters(in: .whitespaces)

        guard !value.isEmpty else {
            throw ConfigError.syntax(line: line.number, message: "`\(key)` entries must not be empty")
        }

        values.append(unquote(value))
        index += 1
    }

    return values
}

func parseMap(
    lines: [ConfigLine],
    index: inout Int,
    parentIndent: Int,
    key: String
) throws -> [(key: String, value: String, line: Int)] {
    var values: [(key: String, value: String, line: Int)] = []

    while index < lines.count {
        let line = lines[index]

        guard line.indent > parentIndent else {
            break
        }

        guard line.indent == parentIndent + 2 else {
            throw ConfigError.syntax(line: line.number, message: "`\(key)` supports one indentation level")
        }

        let pair = try parseKeyValue(line.content, lineNumber: line.number)

        guard let value = pair.value else {
            throw ConfigError.syntax(line: line.number, message: "`\(key).\(pair.key)` requires a scalar value")
        }

        values.append((pair.key, unquote(value), line.number))
        index += 1
    }

    return values
}

func unquote(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespaces)

    if trimmed.count >= 2,
       let first = trimmed.first,
       let last = trimmed.last,
       (first == "\"" && last == "\"") || (first == "'" && last == "'")
    {
        return String(trimmed.dropFirst().dropLast())
    }

    return trimmed
}

func printUsage() {
    print(
        """
        Usage:
          swift tools/fsd-lint.swift [--root <path>] [--config <path>] [--strict|--no-strict] [--architecture|--no-architecture] [--format text|json|xcode|sarif] [--report-root <path>]
          swift tools/fsd-lint.swift FSDDemoApp

        Checks baseline Feature-Sliced Design folder structure:
          - known layers at the source root
          - no deprecated `processes` layer
          - sliced layers contain slices before segments
          - slices contain purpose segments such as `ui` or `model`
          - Swift files are not placed directly on layer/slice boundaries

        With --architecture, also checks Swift type references:
          - dependencies go only from higher FSD layers to lower layers
          - feature/widget/entity slices do not reference sibling slices directly

        Options:
          --root <path>    Source root to inspect. Overrides config root.
          --config <path>  Config file. Defaults to `.fsd-ios.yml` when present.
          --report-root <path>
                           Workspace root used to relativize SARIF file URIs.
          --strict         Treat warnings as errors.
          --no-strict      Disable strict mode even when config enables it.
          --architecture   Enable Swift symbol dependency checks.
          --no-architecture
                           Disable architecture checks even when config enables them.
          --format <value> Output format: text, json, xcode, or sarif. Defaults to text.
        """
    )
}

func findingCounts(_ findings: [Finding]) -> (errors: Int, warnings: Int) {
    (
        errors: findings.filter { $0.severity == .error }.count,
        warnings: findings.filter { $0.severity == .warning }.count
    )
}

func printReport(_ findings: [Finding], format: ReportFormat, rootURL: URL, reportRootURL: URL) {
    switch format {
    case .text:
        printTextReport(findings)
    case .json:
        printJSONReport(findings, rootURL: rootURL)
    case .xcode:
        printXcodeReport(findings)
    case .sarif:
        printSARIFReport(findings, reportRootURL: reportRootURL)
    }
}

func printTextReport(_ findings: [Finding]) {
    for finding in findings {
        print("\(finding.severity.rawValue): \(finding.path): \(finding.message)")
    }

    let counts = findingCounts(findings)

    if counts.errors == 0, counts.warnings == 0 {
        print("FSD lint passed: 0 errors, 0 warnings")
    } else {
        print("FSD lint finished: \(counts.errors) errors, \(counts.warnings) warnings")
    }
}

func printJSONReport(_ findings: [Finding], rootURL: URL) {
    let findingPayloads: [[String: Any]] = findings.map { finding in
        var payload: [String: Any] = [
            "ruleId": finding.ruleId,
            "severity": finding.severity.rawValue,
            "path": finding.path,
            "absolutePath": finding.absolutePath,
            "message": finding.message,
        ]

        if let line = finding.line {
            payload["line"] = line
        }

        if let suggestion = finding.suggestion {
            payload["suggestion"] = suggestion
        }

        return payload
    }

    let counts = findingCounts(findings)
    let payload: [String: Any] = [
        "tool": "fsd-lint",
        "schemaVersion": 1,
        "format": ReportFormat.json.rawValue,
        "root": rootURL.path,
        "summary": [
            "errors": counts.errors,
            "warnings": counts.warnings,
        ],
        "findings": findingPayloads,
    ]

    guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
          let output = String(data: data, encoding: .utf8)
    else {
        print("{\"tool\":\"fsd-lint\",\"schemaVersion\":1,\"format\":\"json\",\"summary\":{\"errors\":0,\"warnings\":0},\"findings\":[]}")
        return
    }

    print(output)
}

func printXcodeReport(_ findings: [Finding]) {
    for finding in findings {
        let line = finding.line ?? 1
        var message = "[\(finding.ruleId)] \(finding.message)"

        if let suggestion = finding.suggestion {
            message += " Suggestion: \(suggestion)"
        }

        print("\(finding.absolutePath):\(line): \(finding.severity.rawValue): \(message)")
    }

    let counts = findingCounts(findings)

    if counts.errors == 0, counts.warnings == 0 {
        print("FSD lint passed: 0 errors, 0 warnings")
    } else {
        print("FSD lint finished: \(counts.errors) errors, \(counts.warnings) warnings")
    }
}

func printSARIFReport(_ findings: [Finding], reportRootURL: URL) {
    let rules: [[String: Any]] = Dictionary(grouping: findings, by: { $0.ruleId })
        .keys
        .sorted()
        .map { ruleId in
            [
                "id": ruleId,
                "shortDescription": [
                    "text": ruleId,
                ],
            ]
        }

    let results: [[String: Any]] = findings.map { finding in
        var message = finding.message

        if let suggestion = finding.suggestion {
            message += " Suggestion: \(suggestion)"
        }

        var region: [String: Any] = [
            "startLine": finding.line ?? 1,
        ]

        if finding.line == nil {
            region["startColumn"] = 1
        }

        return [
            "ruleId": finding.ruleId,
            "level": finding.severity.sarifLevel,
            "message": [
                "text": message,
            ],
            "locations": [
                [
                    "physicalLocation": [
                        "artifactLocation": [
                            "uri": sarifURI(for: finding, reportRootURL: reportRootURL),
                        ],
                        "region": region,
                    ],
                ],
            ],
        ]
    }

    let payload: [String: Any] = [
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [
            [
                "tool": [
                    "driver": [
                        "name": "fsd-lint",
                        "informationUri": "https://github.com/SoundBlaster/FSD",
                        "rules": rules,
                    ],
                ],
                "results": results,
            ],
        ],
    ]

    guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
          let output = String(data: data, encoding: .utf8)
    else {
        print("{\"version\":\"2.1.0\",\"runs\":[{\"tool\":{\"driver\":{\"name\":\"fsd-lint\",\"rules\":[]}},\"results\":[]}]}")
        return
    }

    print(output)
}

func sarifURI(for finding: Finding, reportRootURL: URL) -> String {
    let currentPath = currentDirectoryURL().path
    let reportRootPath = reportRootURL.standardizedFileURL.path
    let absolutePath = URL(fileURLWithPath: finding.absolutePath).standardizedFileURL.path
    let path: String

    if absolutePath == reportRootPath {
        path = URL(fileURLWithPath: absolutePath).lastPathComponent
    } else if absolutePath.hasPrefix("\(reportRootPath)/") {
        path = String(absolutePath.dropFirst(reportRootPath.count + 1))
    } else if absolutePath == currentPath {
        path = URL(fileURLWithPath: absolutePath).lastPathComponent
    } else if absolutePath.hasPrefix("\(currentPath)/") {
        path = String(absolutePath.dropFirst(currentPath.count + 1))
    } else {
        path = finding.path
    }

    return path
        .split(separator: "/")
        .map { component in
            String(component).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(component)
        }
        .joined(separator: "/")
}

extension Severity {
    var sarifLevel: String {
        switch self {
        case .error:
            return "error"
        case .warning:
            return "warning"
        }
    }
}

func currentDirectoryURL() -> URL {
    URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .standardizedFileURL
}

func makeURL(from path: String, relativeTo baseURL: URL = currentDirectoryURL()) -> URL {
    if path.hasPrefix("/") {
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    return baseURL
        .appendingPathComponent(path)
        .standardizedFileURL
}

guard let argumentConfiguration = parseArguments(Array(CommandLine.arguments.dropFirst())) else {
    exit(0)
}

let configuration: Configuration

do {
    configuration = try makeConfiguration(from: argumentConfiguration)
} catch let error as ConfigError {
    print("error: \(error.description)")
    exit(2)
} catch {
    print("error: \(error.localizedDescription)")
    exit(1)
}

let rootURL = makeURL(from: configuration.rootPath)
let reportRootURL = configuration.reportRootPath.map { makeURL(from: $0) } ?? currentDirectoryURL()
let findings = FSDLinter(
    rootURL: rootURL,
    strict: configuration.strict,
    architectureChecksEnabled: configuration.architecture,
    ignoredPaths: configuration.ignoredPaths,
    layerConfiguration: configuration.layers,
    rules: configuration.rules
).run()

printReport(findings, format: configuration.format, rootURL: rootURL, reportRootURL: reportRootURL)

exit(findingCounts(findings).errors == 0 ? 0 : 1)
