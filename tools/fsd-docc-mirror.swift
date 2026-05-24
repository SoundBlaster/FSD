#!/usr/bin/env swift
//
//  fsd-docc-mirror.swift
//  FSDDemoApp
//
//  Generates DocC article mirrors for repository Markdown documentation.
//

import Foundation

struct SourceDocument {
    let path: String
    let title: String
    let articleName: String
}

enum Mode {
    case write
    case check
}

let documents: [SourceDocument] = [
    SourceDocument(path: "README.md", title: "Repository Overview", articleName: "RepositoryOverview"),
    SourceDocument(path: "ARCHITECTURE.md", title: "Architecture Contract", articleName: "ArchitectureContract"),
    SourceDocument(path: "CONTRIBUTING.md", title: "Contribution Guide", articleName: "ContributionGuide"),
    SourceDocument(path: "CHANGELOG.md", title: "Changelog", articleName: "Changelog"),
    SourceDocument(path: "docs/showcase.md", title: "Repository Showcase", articleName: "RepositoryShowcase"),
    SourceDocument(path: "docs/checklist.md", title: "Review Checklist", articleName: "ReviewChecklist"),
    SourceDocument(path: "docs/cli.md", title: "CLI Guide", articleName: "CLIGuide"),
    SourceDocument(path: "docs/configuration.md", title: "Configuration Contract", articleName: "ConfigurationContract"),
    SourceDocument(path: "docs/release.md", title: "Release Process", articleName: "ReleaseProcess"),
    SourceDocument(path: "docs/roadmap.md", title: "Roadmap", articleName: "Roadmap"),
    SourceDocument(path: "docs/adoption/external-project.md", title: "External Project Adoption", articleName: "ExternalProjectAdoption"),
    SourceDocument(path: "docs/rules/fsd-layers.md", title: "FSD Layer Rules", articleName: "FSDLayerRules"),
    SourceDocument(path: "docs/rules/fsd-imports.md", title: "FSD Import Rules", articleName: "FSDImportRules"),
    SourceDocument(path: "docs/rules/fsd-slices.md", title: "FSD Slice Rules", articleName: "FSDSliceRules"),
    SourceDocument(path: "docs/rules/fsd-swiftui.md", title: "SwiftUI FSD Rules", articleName: "SwiftUIFSDRules"),
    SourceDocument(path: "docs/rules/fsd-testing.md", title: "FSD Testing Rules", articleName: "FSDTestingRules"),
    SourceDocument(path: "specs/fsd.md", title: "Feature-Sliced Design Specification", articleName: "FeatureSlicedDesignSpecification"),
    SourceDocument(path: "specs/fsd-with-spm.md", title: "FSD with Swift Package Manager", articleName: "FSDWithSwiftPackageManager"),
]

let fileManager = FileManager.default
let currentDirectoryURL = URL(fileURLWithPath: fileManager.currentDirectoryPath).standardizedFileURL
let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0], relativeTo: currentDirectoryURL)
    .standardizedFileURL
let toolsDirectoryURL = scriptURL.deletingLastPathComponent()
let repoRootURL = toolsDirectoryURL.lastPathComponent == "tools"
    ? toolsDirectoryURL.deletingLastPathComponent()
    : currentDirectoryURL
let catalogURL = repoRootURL
    .appendingPathComponent("Sources/FSDToolingSupport/Documentation.docc", isDirectory: true)
let mirrorURL = catalogURL.appendingPathComponent("MirroredDocumentation", isDirectory: true)
let repositoryBlobBaseURL = "https://github.com/SoundBlaster/FSD/blob/main"
let repositoryTreeBaseURL = "https://github.com/SoundBlaster/FSD/tree/main"

let articleByPath = Dictionary(uniqueKeysWithValues: documents.map { ($0.path, $0.articleName) })

func printUsage() {
    print(
        """
        Usage:
          swift tools/fsd-docc-mirror.swift [--check]

        Modes:
          default   Regenerate DocC mirror articles from repository Markdown docs.
          --check   Verify committed DocC mirror articles match source docs.
        """
    )
}

func parseMode() -> Mode {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments.isEmpty {
        return .write
    }
    if arguments == ["--check"] {
        return .check
    }
    if arguments == ["--help"] || arguments == ["-h"] {
        printUsage()
        exit(0)
    }

    fputs("error: unsupported arguments: \(arguments.joined(separator: " "))\n", stderr)
    printUsage()
    exit(2)
}

let mode = parseMode()

func repositoryRelativePath(for url: URL) -> String {
    let rootPath = repoRootURL.path
    let path = url.standardizedFileURL.path
    guard path.hasPrefix(rootPath + "/") else {
        return path
    }
    return String(path.dropFirst(rootPath.count + 1))
}

func normalizedRepositoryPath(_ rawPath: String, relativeTo sourcePath: String) -> String? {
    let trimmedPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedPath.isEmpty,
          !trimmedPath.hasPrefix("#"),
          !trimmedPath.hasPrefix("http://"),
          !trimmedPath.hasPrefix("https://"),
          !trimmedPath.hasPrefix("mailto:"),
          !trimmedPath.hasPrefix("<doc:") else {
        return nil
    }

    let pathWithoutFragment = trimmedPath.split(separator: "#", maxSplits: 1).first.map(String.init) ?? trimmedPath
    let pathWithoutQuery = pathWithoutFragment.split(separator: "?", maxSplits: 1).first.map(String.init) ?? pathWithoutFragment
    guard !pathWithoutQuery.isEmpty else {
        return nil
    }

    let sourceDirectory = URL(fileURLWithPath: sourcePath, relativeTo: repoRootURL)
        .deletingLastPathComponent()
    let targetURL = URL(fileURLWithPath: pathWithoutQuery, relativeTo: sourceDirectory)
        .standardizedFileURL
    return repositoryRelativePath(for: targetURL)
}

func rewrittenDestination(_ rawDestination: String, relativeTo sourcePath: String) -> String {
    guard let repositoryPath = normalizedRepositoryPath(rawDestination, relativeTo: sourcePath) else {
        return rawDestination
    }

    if let articleName = articleByPath[repositoryPath] {
        return "<doc:\(articleName)>"
    }

    let encodedPath = repositoryPath
        .split(separator: "/")
        .map { segment in
            String(segment).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(segment)
        }
        .joined(separator: "/")
    var isDirectory: ObjCBool = false
    let targetURL = repoRootURL.appendingPathComponent(repositoryPath)
    let repositoryBaseURL = fileManager.fileExists(atPath: targetURL.path, isDirectory: &isDirectory)
        && isDirectory.boolValue
        ? repositoryTreeBaseURL
        : repositoryBlobBaseURL
    return "\(repositoryBaseURL)/\(encodedPath)"
}

func rewriteMarkdownLinks(in content: String, sourcePath: String) -> String {
    let pattern = #"\[([^\]]+)\]\(([^)\s]+)\)"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let nsRange = NSRange(content.startIndex..<content.endIndex, in: content)
    var output = content

    for match in regex.matches(in: content, range: nsRange).reversed() {
        guard match.numberOfRanges == 3,
              let fullRange = Range(match.range(at: 0), in: output),
              let labelRange = Range(match.range(at: 1), in: content),
              let destinationRange = Range(match.range(at: 2), in: content) else {
            continue
        }

        let label = String(content[labelRange])
        let destination = String(content[destinationRange])
        let rewritten = rewrittenDestination(destination, relativeTo: sourcePath)
        output.replaceSubrange(fullRange, with: "[\(label)](\(rewritten))")
    }

    return output
}

func bodyWithoutOriginalTopLevelTitle(_ content: String) -> String {
    var lines = content.components(separatedBy: .newlines)
    if let firstNonEmptyIndex = lines.firstIndex(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
       lines[firstNonEmptyIndex].hasPrefix("# ") {
        lines.remove(at: firstNonEmptyIndex)
    }
    return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
}

func mirroredArticle(for document: SourceDocument) throws -> String {
    let sourceURL = repoRootURL.appendingPathComponent(document.path)
    let sourceContent = try String(contentsOf: sourceURL, encoding: .utf8)
    let rewrittenContent = rewriteMarkdownLinks(
        in: bodyWithoutOriginalTopLevelTitle(sourceContent),
        sourcePath: document.path
    )

    return """
    # \(document.title)

    > Source: `\(document.path)`

    \(rewrittenContent)
    """
}

func mirrorIndex() -> String {
    let rows = documents
        .map { "- <doc:\($0.articleName)>" }
        .joined(separator: "\n")

    return """
    # Documentation Mirror

    Browse the repository Markdown documentation as DocC articles published on
    GitHub Pages.

    The mirror is generated by `tools/fsd-docc-mirror.swift` before DocC builds,
    so the published site stays aligned with repository documentation.

    ## Topics

    ### Repository

    \(rows)
    """ + "\n"
}

func expectedArticles() throws -> [String: String] {
    var articles = ["DocumentationMirror.md": mirrorIndex()]
    for document in documents {
        articles["\(document.articleName).md"] = try mirroredArticle(for: document)
    }
    return articles
}

func writeMirror() throws {
    if fileManager.fileExists(atPath: mirrorURL.path) {
        try fileManager.removeItem(at: mirrorURL)
    }
    try fileManager.createDirectory(at: mirrorURL, withIntermediateDirectories: true)

    for (fileName, content) in try expectedArticles() {
        try content.write(
            to: mirrorURL.appendingPathComponent(fileName),
            atomically: true,
            encoding: .utf8
        )
    }

    print("Generated DocC documentation mirror: \(documents.count) source files")
}

func checkMirror() throws -> Bool {
    let expected = try expectedArticles()
    var failures: [String] = []

    for (fileName, expectedContent) in expected.sorted(by: { $0.key < $1.key }) {
        let fileURL = mirrorURL.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            failures.append("missing: \(repositoryRelativePath(for: fileURL))")
            continue
        }

        let currentContent = try String(contentsOf: fileURL, encoding: .utf8)
        if currentContent != expectedContent {
            failures.append("stale: \(repositoryRelativePath(for: fileURL))")
        }
    }

    if let enumerator = fileManager.enumerator(
        at: mirrorURL,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    ) {
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true,
                  fileURL.pathExtension == "md" else {
                continue
            }

            let fileName = fileURL.lastPathComponent
            if expected[fileName] == nil {
                failures.append("extra: \(repositoryRelativePath(for: fileURL))")
            }
        }
    }

    if failures.isEmpty {
        print("DocC documentation mirror is up to date: \(documents.count) source files")
        return true
    }

    fputs("DocC documentation mirror is out of date.\n", stderr)
    for failure in failures {
        fputs("- \(failure)\n", stderr)
    }
    fputs("Run `make docc-mirror` and commit the generated files.\n", stderr)
    return false
}

switch mode {
case .write:
    try writeMirror()
case .check:
    if try !checkMirror() {
        exit(1)
    }
}
