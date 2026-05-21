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

struct Finding {
    let severity: Severity
    let path: String
    let message: String
}

struct Configuration {
    let rootPath: String
    let strict: Bool
    let architecture: Bool
}

struct FSDLinter {
    private let fileManager = FileManager.default
    private let rootURL: URL
    private let strict: Bool
    private let architectureChecksEnabled: Bool

    private let layers: Set<String> = [
        "app",
        "pages",
        "widgets",
        "features",
        "entities",
        "shared",
    ]

    private let slicedLayers: Set<String> = [
        "pages",
        "widgets",
        "features",
        "entities",
    ]

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

    private let layerRanks: [String: Int] = [
        "shared": 0,
        "entities": 1,
        "features": 2,
        "widgets": 3,
        "pages": 4,
        "app": 5,
    ]

    private let sameLayerSliceIsolationLayers: Set<String> = [
        "widgets",
        "features",
        "entities",
    ]

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

    init(rootURL: URL, strict: Bool, architectureChecksEnabled: Bool) {
        self.rootURL = rootURL
        self.strict = strict
        self.architectureChecksEnabled = architectureChecksEnabled
    }

    func run() -> [Finding] {
        var findings: [Finding] = []

        guard directoryExists(rootURL) else {
            return [
                Finding(
                    severity: .error,
                    path: rootURL.path,
                    message: "FSD root does not exist or is not a directory"
                ),
            ]
        }

        lintRoot(&findings)
        lintSlicedLayers(&findings)
        lintSlicelessLayers(&findings)

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
                    error(directory, "Deprecated FSD layer `processes` should not be used")
                )
                continue
            }

            guard !layers.contains(name), !allowedRootDirectories.contains(name) else {
                continue
            }

            findings.append(
                warning(directory, "Directory is outside known FSD layers")
            )
        }

        for file in childFiles(of: rootURL) where file.pathExtension == "swift" {
            findings.append(
                error(file, "Swift files should live inside an FSD layer")
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
                    error(file, "Swift files in sliced layers should live inside a slice segment")
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
                    "Sliced layer `\(layer)` must contain slices first; `\(sliceName)` looks like a segment"
                )
            )
        }

        let segmentURLs = childDirectories(of: sliceURL)

        if segmentURLs.isEmpty {
            findings.append(
                error(sliceURL, "Slice has no segments such as `ui`, `model`, `api`, or `lib`")
            )
        }

        for file in childFiles(of: sliceURL) where file.pathExtension == "swift" {
            findings.append(
                error(file, "Swift files should live inside a segment, not directly in a slice")
            )
        }

        for segmentURL in segmentURLs {
            let segmentName = segmentURL.lastPathComponent

            if !sliceSegments.contains(segmentName) {
                findings.append(
                    warning(
                        segmentURL,
                        "Unexpected segment `\(segmentName)` in `\(layer)/\(sliceName)`"
                    )
                )
            }

            lintReservedNestedSegments(in: segmentURL, findings: &findings)
        }
    }

    private func lintSlicelessLayers(_ findings: inout [Finding]) {
        lintSlicelessLayer(
            name: "app",
            allowedSegments: appSegments,
            findings: &findings
        )

        lintSlicelessLayer(
            name: "shared",
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
                warning(file, "Consider moving Swift files into a purpose segment")
            )
        }

        for segmentURL in childDirectories(of: layerURL) {
            let segmentName = segmentURL.lastPathComponent

            if name == "app", segmentName == "ui" {
                findings.append(
                    error(segmentURL, "`app/ui` is discouraged; UI should usually live in pages/widgets/features/entities/shared")
                )
                continue
            }

            if layers.contains(segmentName) {
                findings.append(
                    error(segmentURL, "FSD layer name `\(segmentName)` should not be nested inside `\(name)`")
                )
                continue
            }

            if !allowedSegments.contains(segmentName) {
                findings.append(
                    warning(segmentURL, "Unexpected segment `\(segmentName)` in `\(name)` layer")
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
                warning(directory, "Nested directory reuses reserved segment name `\(name)`")
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

                let key = "\(sourceFile.relativePath)|\(targetFile.relativePath)|\(reference)|\(violation)"

                guard !emittedFindings.contains(key) else {
                    continue
                }

                emittedFindings.insert(key)
                findings.append(error(sourceFile.url, violation))
            }
        }
    }

    private func dependencyViolation(
        from sourceFile: SourceFile,
        to targetFile: SourceFile,
        symbol: String
    ) -> String? {
        guard let sourceLayer = sourceFile.layer,
              let targetLayer = targetFile.layer,
              let sourceRank = layerRanks[sourceLayer],
              let targetRank = layerRanks[targetLayer]
        else {
            return nil
        }

        if sourceLayer == targetLayer {
            guard sameLayerSliceIsolationLayers.contains(sourceLayer),
                  sourceFile.slice != nil,
                  targetFile.slice != nil,
                  sourceFile.slice != targetFile.slice
            else {
                return nil
            }

            return "Same-layer slices should not depend on each other: `\(sourceLayer)/\(sourceFile.slice ?? "")` references `\(symbol)` from `\(targetLayer)/\(targetFile.slice ?? "")`"
        }

        guard sourceRank < targetRank else {
            return nil
        }

        return "Invalid FSD dependency direction: `\(sourceLayer)` references `\(symbol)` from higher layer `\(targetLayer)`"
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

        return urls.sorted { $0.path < $1.path }
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
            guard let url = item as? URL, url.pathExtension == "swift" else {
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

    private func error(_ url: URL, _ message: String) -> Finding {
        Finding(severity: .error, path: relativePath(for: url), message: message)
    }

    private func warning(_ url: URL, _ message: String) -> Finding {
        Finding(
            severity: strict ? .error : .warning,
            path: relativePath(for: url),
            message: message
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
}

func parseArguments(_ arguments: [String]) -> Configuration? {
    var rootPath = "FSDDemoApp"
    var strict = false
    var architecture = false
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--help", "-h":
            printUsage()
            return nil
        case "--strict":
            strict = true
        case "--architecture":
            architecture = true
        case "--root":
            index += 1
            guard index < arguments.count else {
                print("error: --root requires a path")
                exit(2)
            }
            rootPath = arguments[index]
        default:
            if argument.hasPrefix("-") {
                print("error: unknown option \(argument)")
                exit(2)
            }
            rootPath = argument
        }

        index += 1
    }

    return Configuration(rootPath: rootPath, strict: strict, architecture: architecture)
}

func printUsage() {
    print(
        """
        Usage:
          swift tools/fsd-lint.swift [--root <path>] [--strict] [--architecture]
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
          --root <path>    Source root to inspect. Defaults to `FSDDemoApp`.
          --strict         Treat warnings as errors.
          --architecture   Enable Swift symbol dependency checks.
        """
    )
}

func makeRootURL(from path: String) -> URL {
    if path.hasPrefix("/") {
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(path)
        .standardizedFileURL
}

guard let configuration = parseArguments(Array(CommandLine.arguments.dropFirst())) else {
    exit(0)
}

let rootURL = makeRootURL(from: configuration.rootPath)
let findings = FSDLinter(
    rootURL: rootURL,
    strict: configuration.strict,
    architectureChecksEnabled: configuration.architecture
).run()

for finding in findings {
    print("\(finding.severity.rawValue): \(finding.path): \(finding.message)")
}

let errorCount = findings.filter { $0.severity == .error }.count
let warningCount = findings.filter { $0.severity == .warning }.count

if errorCount == 0, warningCount == 0 {
    print("FSD lint passed: 0 errors, 0 warnings")
} else {
    print("FSD lint finished: \(errorCount) errors, \(warningCount) warnings")
}

exit(errorCount == 0 ? 0 : 1)
