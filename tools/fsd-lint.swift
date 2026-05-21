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
}

struct FSDLinter {
    private let fileManager = FileManager.default
    private let rootURL: URL
    private let strict: Bool

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

    init(rootURL: URL, strict: Bool) {
        self.rootURL = rootURL
        self.strict = strict
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
        let path = url.path

        guard path.hasPrefix(rootPath) else {
            return path
        }

        let startIndex = path.index(path.startIndex, offsetBy: rootPath.count)
        let relative = String(path[startIndex...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return relative.isEmpty ? "." : relative
    }
}

func parseArguments(_ arguments: [String]) -> Configuration? {
    var rootPath = "FSDDemoApp"
    var strict = false
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--help", "-h":
            printUsage()
            return nil
        case "--strict":
            strict = true
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

    return Configuration(rootPath: rootPath, strict: strict)
}

func printUsage() {
    print(
        """
        Usage:
          swift tools/fsd-lint.swift [--root <path>] [--strict]
          swift tools/fsd-lint.swift FSDDemoApp

        Checks baseline Feature-Sliced Design folder structure:
          - known layers at the source root
          - no deprecated `processes` layer
          - sliced layers contain slices before segments
          - slices contain purpose segments such as `ui` or `model`
          - Swift files are not placed directly on layer/slice boundaries

        Options:
          --root <path>  Source root to inspect. Defaults to `FSDDemoApp`.
          --strict       Treat warnings as errors.
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
let findings = FSDLinter(rootURL: rootURL, strict: configuration.strict).run()

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
