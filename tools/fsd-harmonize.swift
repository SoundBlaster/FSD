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
    let exactSuggestionCount: Int?
    let expectedSuggestionCount: Int?
}

enum HarmonizeConfidence: String {
    case high
    case medium
    case low
}

enum HarmonizeImpact: String {
    case architecture
    case naming
    case reuse
    case maintainability
}

struct HarmonizeSuggestion: Hashable {
    let ruleId: String
    let confidence: HarmonizeConfidence
    let impact: HarmonizeImpact
    let path: String
    let title: String
    let evidence: [String]
    let why: String
    let recommendation: String
    let nextSteps: [String]
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
                return $0.ruleId < $1.ruleId
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
            let pathTokens = Set(tokenize(relative))

            guard let token = entityTokens.first(where: { pathTokens.contains($0) }) else {
                continue
            }

            guard !emittedPaths.contains(where: { relative.hasPrefix("\($0)/") }) else {
                continue
            }

            emittedPaths.append(relative)

            suggestions.insert(
                HarmonizeSuggestion(
                    ruleId: "harmonize/shared-domain-language",
                    confidence: .high,
                    impact: .architecture,
                    path: relative,
                    title: "`shared` appears to contain domain language",
                    evidence: [
                        "Matched entity token `\(token)` inferred from `entities`.",
                        "Path under `shared`: `\(relative)`.",
                    ],
                    why: "`shared` should stay generic, but this path contains the entity token `\(token)`.",
                    recommendation: "Move business-specific code to `entities/\(token)`, a feature owner, or a page-local segment.",
                    nextSteps: [
                        "Check whether the code models `\(token)` as domain behavior.",
                        "Move reusable domain code to `entities/\(token)` or keep one-off code in its page owner.",
                    ]
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
                        ruleId: "harmonize/vague-slice-name",
                        confidence: vagueSliceNames.contains(normalizedName) ? .high : .medium,
                        impact: .naming,
                        path: relativePath(for: sliceURL),
                        title: "Slice name is technical or vague",
                        evidence: [
                            "Slice name: `\(sliceName)`.",
                            "Layer: `\(layer)`.",
                        ],
                        why: "FSD slices should use product/business language, while `\(sliceName)` does not explain ownership.",
                        recommendation: "Rename the slice around the user action, domain concept, or route it actually owns.",
                        nextSteps: [
                            "Identify the route, user action, or domain object owned by this slice.",
                            "Rename the slice with that business meaning in kebab-case.",
                        ]
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
                    ruleId: "harmonize/large-page-slice",
                    confidence: .medium,
                    impact: .reuse,
                    path: relativePath(for: pageURL),
                    title: "Page slice is getting large",
                    evidence: [
                        "Swift files under page: \(swiftFileCount).",
                        "Threshold: 6 Swift files.",
                    ],
                    why: "This page owns \(swiftFileCount) Swift files. Large pages often hide reusable widgets or features.",
                    recommendation: "Look for reusable composition blocks for `widgets` or user actions for `features`.",
                    nextSteps: [
                        "Group UI composition files that could become a `widgets` slice.",
                        "Group user action files that could become a `features` slice.",
                    ]
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
        var normalized = ""
        var previousWasLowercaseOrDigit = false

        for character in value {
            if isTokenSeparator(character) {
                normalized.append(" ")
                previousWasLowercaseOrDigit = false
                continue
            }

            let text = String(character)
            let isUppercase = text.rangeOfCharacter(from: .uppercaseLetters) != nil

            if isUppercase, previousWasLowercaseOrDigit {
                normalized.append(" ")
            }

            normalized.append(contentsOf: text.lowercased())
            previousWasLowercaseOrDigit = text.rangeOfCharacter(from: .lowercaseLetters) != nil ||
                text.rangeOfCharacter(from: .decimalDigits) != nil
        }

        return normalized
            .split { character in
                character == " "
            }
            .map(String.init)
            .filter { $0.count >= 3 }
    }

    private func isTokenSeparator(_ character: Character) -> Bool {
        character == "/" ||
            character == "-" ||
            character == "_" ||
            character == " " ||
            character == "."
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
    var exactSuggestionCount: Int?
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
        case "--expect-suggestions":
            index += 1
            guard index < arguments.count, let count = Int(arguments[index]) else {
                print("error: --expect-suggestions requires an integer")
                exit(2)
            }
            exactSuggestionCount = count
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
        exactSuggestionCount: exactSuggestionCount,
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
          --expect-suggestions <count>          Test helper. Fails unless exactly this many suggestions are found.
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
    print("FSD harmonize found no suggestions")
} else {
    print("FSD harmonize suggestions:")

    for (index, suggestion) in suggestions.enumerated() {
        print("")
        print("\(index + 1). [\(suggestion.ruleId)] \(suggestion.path)")
        print("   Confidence: \(suggestion.confidence.rawValue)")
        print("   Impact: \(suggestion.impact.rawValue)")
        print("   \(suggestion.title)")
        print("   Evidence:")
        for evidence in suggestion.evidence {
            print("   - \(evidence)")
        }
        print("   Why: \(suggestion.why)")
        print("   Recommendation: \(suggestion.recommendation)")
        print("   Next steps:")
        for step in suggestion.nextSteps {
            print("   - \(step)")
        }
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

if let exactSuggestionCount = configuration.exactSuggestionCount {
    guard suggestions.count == exactSuggestionCount else {
        print(
            "error: expected exactly \(exactSuggestionCount) suggestions, found \(suggestions.count)"
        )
        exit(1)
    }

    print("Expectation satisfied: found exactly \(exactSuggestionCount) suggestions")
}

exit(0)
