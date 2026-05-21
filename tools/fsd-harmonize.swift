#!/usr/bin/env swift
//
//  fsd-harmonize.swift
//  FSDDemoApp
//
//  Read-only FSD advisor for coherent refactoring suggestions.
//

import Foundation

struct HarmonizeConfiguration {
    let rootPath: String
    let expectedSuggestionCount: Int?
}

struct HarmonizeSuggestion: Hashable {
    let id: String
    let path: String
    let title: String
    let why: String
    let consider: String
}

struct HarmonizeAdvisor {
    private let fileManager = FileManager.default
    private let rootURL: URL

    private let slicedLayers = [
        "pages",
        "widgets",
        "features",
        "entities",
    ]

    private let vagueSliceNames: Set<String> = [
        "base",
        "common",
        "components",
        "do-stuff",
        "general",
        "helpers",
        "misc",
        "modules",
        "stuff",
        "utils",
    ]

    private let technicalNameFragments = [
        "component",
        "helper",
        "manager",
        "module",
        "service",
        "stuff",
        "util",
    ]

    init(rootURL: URL) {
        self.rootURL = rootURL
    }

    func run() -> [HarmonizeSuggestion] {
        var suggestions: Set<HarmonizeSuggestion> = []
        let entityTokens = inferEntityTokens()

        collectSharedDomainSuggestions(entityTokens: entityTokens, into: &suggestions)
        collectVagueSliceNameSuggestions(into: &suggestions)
        collectLargePageSuggestions(into: &suggestions)

        return suggestions.sorted {
            if $0.path == $1.path {
                return $0.id < $1.id
            }

            return $0.path < $1.path
        }
    }

    private func collectSharedDomainSuggestions(
        entityTokens: Set<String>,
        into suggestions: inout Set<HarmonizeSuggestion>
    ) {
        guard !entityTokens.isEmpty else {
            return
        }

        let sharedURL = rootURL.appendingPathComponent("shared")

        guard directoryExists(sharedURL) else {
            return
        }

        var emittedPaths: [String] = []

        for url in recursiveChildren(of: sharedURL) {
            let relative = relativePath(for: url)
            let lowercasePath = relative.lowercased()

            guard let token = entityTokens.first(where: { lowercasePath.contains($0) }) else {
                continue
            }

            guard !emittedPaths.contains(where: { relative.hasPrefix("\($0)/") }) else {
                continue
            }

            emittedPaths.append(relative)

            suggestions.insert(
                HarmonizeSuggestion(
                    id: "shared-domain-language",
                    path: relative,
                    title: "`shared` appears to contain domain language",
                    why: "`shared` should stay generic, but this path contains the entity token `\(token)`.",
                    consider: "Move business-specific code to `entities/\(token)`, a feature owner, or a page-local segment."
                )
            )
        }
    }

    private func collectVagueSliceNameSuggestions(into suggestions: inout Set<HarmonizeSuggestion>) {
        for layer in slicedLayers {
            let layerURL = rootURL.appendingPathComponent(layer)

            guard directoryExists(layerURL) else {
                continue
            }

            for sliceURL in childDirectories(of: layerURL) {
                let sliceName = sliceURL.lastPathComponent
                let normalizedName = sliceName.lowercased()

                guard vagueSliceNames.contains(normalizedName) ||
                    technicalNameFragments.contains(where: { normalizedName.contains($0) })
                else {
                    continue
                }

                suggestions.insert(
                    HarmonizeSuggestion(
                        id: "vague-slice-name",
                        path: relativePath(for: sliceURL),
                        title: "Slice name is technical or vague",
                        why: "FSD slices should use product/business language, while `\(sliceName)` does not explain ownership.",
                        consider: "Rename the slice around the user action, domain concept, or route it actually owns."
                    )
                )
            }
        }
    }

    private func collectLargePageSuggestions(into suggestions: inout Set<HarmonizeSuggestion>) {
        let pagesURL = rootURL.appendingPathComponent("pages")

        guard directoryExists(pagesURL) else {
            return
        }

        for pageURL in childDirectories(of: pagesURL) {
            let swiftFileCount = swiftFiles(under: pageURL).count

            guard swiftFileCount >= 6 else {
                continue
            }

            suggestions.insert(
                HarmonizeSuggestion(
                    id: "large-page-slice",
                    path: relativePath(for: pageURL),
                    title: "Page slice is getting large",
                    why: "This page owns \(swiftFileCount) Swift files. Large pages often hide reusable widgets or features.",
                    consider: "Look for reusable composition blocks for `widgets` or user actions for `features`."
                )
            )
        }
    }

    private func inferEntityTokens() -> Set<String> {
        let entitiesURL = rootURL.appendingPathComponent("entities")

        guard directoryExists(entitiesURL) else {
            return []
        }

        return Set(
            childDirectories(of: entitiesURL).flatMap { entityURL in
                tokenize(entityURL.lastPathComponent)
            }
        )
    }

    private func tokenize(_ value: String) -> [String] {
        value
            .lowercased()
            .split { character in
                character == "-" || character == "_" || character == " "
            }
            .map(String.init)
            .filter { $0.count >= 3 }
    }

    private func childDirectories(of url: URL) -> [URL] {
        children(of: url).filter(directoryExists)
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

    private func recursiveChildren(of url: URL) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { $0 as? URL }.sorted { $0.path < $1.path }
    }

    private func swiftFiles(under url: URL) -> [URL] {
        recursiveChildren(of: url).filter { $0.pathExtension == "swift" }
    }

    private func directoryExists(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
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
}

func parseHarmonizeArguments(_ arguments: [String]) -> HarmonizeConfiguration? {
    var rootPath = "FSDDemoApp"
    var expectedSuggestionCount: Int?
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--help", "-h":
            printHarmonizeUsage()
            return nil
        case "--root":
            index += 1
            guard index < arguments.count else {
                print("error: --root requires a path")
                exit(2)
            }
            rootPath = arguments[index]
        case "--expect-suggestions-at-least":
            index += 1
            guard index < arguments.count, let count = Int(arguments[index]) else {
                print("error: --expect-suggestions-at-least requires an integer")
                exit(2)
            }
            expectedSuggestionCount = count
        default:
            if argument.hasPrefix("-") {
                print("error: unknown option \(argument)")
                exit(2)
            }
            rootPath = argument
        }

        index += 1
    }

    return HarmonizeConfiguration(
        rootPath: rootPath,
        expectedSuggestionCount: expectedSuggestionCount
    )
}

func printHarmonizeUsage() {
    print(
        """
        Usage:
          swift tools/fsd-harmonize.swift [--root <path>]
          swift tools/fsd-harmonize.swift FSDDemoApp

        Produces read-only FSD refactoring suggestions:
          - domain language leaking into `shared`
          - vague or technical slice names
          - large page slices that may hide reusable widgets or features

        The default mode is advisory and exits with 0 even when suggestions exist.

        Options:
          --root <path>                         Source root to inspect. Defaults to `FSDDemoApp`.
          --expect-suggestions-at-least <count> Test helper. Fails if fewer suggestions are found.
        """
    )
}

func makeHarmonizeRootURL(from path: String) -> URL {
    if path.hasPrefix("/") {
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(path)
        .standardizedFileURL
}

guard let configuration = parseHarmonizeArguments(Array(CommandLine.arguments.dropFirst())) else {
    exit(0)
}

let rootURL = makeHarmonizeRootURL(from: configuration.rootPath)

var isDirectory: ObjCBool = false
guard FileManager.default.fileExists(atPath: rootURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue
else {
    print("error: FSD root does not exist or is not a directory: \(rootURL.path)")
    exit(1)
}

let suggestions = HarmonizeAdvisor(rootURL: rootURL).run()

if suggestions.isEmpty {
    print("FSD harmonize found no high-confidence suggestions")
} else {
    print("FSD harmonize suggestions:")

    for (index, suggestion) in suggestions.enumerated() {
        print("")
        print("\(index + 1). [\(suggestion.id)] \(suggestion.path)")
        print("   \(suggestion.title)")
        print("   Why: \(suggestion.why)")
        print("   Consider: \(suggestion.consider)")
    }

    print("")
    print("FSD harmonize finished: \(suggestions.count) suggestions")
}

if let expectedSuggestionCount = configuration.expectedSuggestionCount {
    guard suggestions.count >= expectedSuggestionCount else {
        print(
            "error: expected at least \(expectedSuggestionCount) suggestions, found \(suggestions.count)"
        )
        exit(1)
    }

    print("Expectation satisfied: found at least \(expectedSuggestionCount) suggestions")
}

exit(0)
