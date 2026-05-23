import Foundation
import PackagePlugin

@main
struct FSDGeneratorPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        if arguments.isEmpty || isPluginHelp(arguments) {
            printUsage()
            return
        }

        let commandArguments = normalizedCreateArguments(arguments)
        let packageDirectoryURL = context.package.directoryURL
        let fsdIOSScriptURL = packageDirectoryURL
            .appendingPathComponent("tools")
            .appendingPathComponent("fsd-ios.swift")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", fsdIOSScriptURL.path] + commandArguments
        process.currentDirectoryURL = packageDirectoryURL

        try process.run()
        process.waitUntilExit()

        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            throw PluginError.commandFailed(process.terminationStatus)
        }
    }

    private func normalizedCreateArguments(_ arguments: [String]) -> [String] {
        arguments.first == "create" ? arguments : ["create"] + arguments
    }

    private func isPluginHelp(_ arguments: [String]) -> Bool {
        guard let first = arguments.first else {
            return false
        }

        return first == "--help" || first == "-h"
    }

    private func printUsage() {
        print(
            """
            Usage:
              swift package --allow-writing-to-package-directory fsd-generate slice page|feature|entity <name> [--root <path>] [--dry-run]
              swift package --allow-writing-to-package-directory fsd-generate module <Name> --output <path> [--dry-run]

            Examples:
              swift package --allow-writing-to-package-directory fsd-generate slice feature export-report --root Sources/App
              swift package --allow-writing-to-package-directory fsd-generate module Reporting --output Packages/ReportingModule

            The plugin delegates to the fsd-ios CLI target, so generated output,
            validation, dry-run behavior, and overwrite protection stay identical
            to `fsd-ios create`.

            Use SwiftPM's --allow-writing-to-directory <path> permission when
            intentionally writing generated output outside the package directory.
            """
        )
    }
}

enum PluginError: Error, CustomStringConvertible {
    case commandFailed(Int32)

    var description: String {
        switch self {
        case .commandFailed(let status):
            return "fsd-ios generator command failed with exit code \(status)"
        }
    }
}
