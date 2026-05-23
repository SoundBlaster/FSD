import Foundation
import PackagePlugin

@main
struct FSDGeneratorPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        if arguments.isEmpty || arguments.contains("--help") || arguments.contains("-h") {
            printUsage()
            return
        }

        let fsdIOS = try context.tool(named: "fsd-ios")
        let commandArguments = normalizedCreateArguments(arguments)

        let process = Process()
        process.executableURL = fsdIOS.url
        process.arguments = commandArguments
        process.currentDirectoryURL = context.package.directoryURL

        try process.run()
        process.waitUntilExit()

        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            throw PluginError.commandFailed(process.terminationStatus)
        }
    }

    private func normalizedCreateArguments(_ arguments: [String]) -> [String] {
        arguments.first == "create" ? arguments : ["create"] + arguments
    }

    private func printUsage() {
        print(
            """
            Usage:
              swift package --allow-writing-to-package-directory fsd-generate slice page|feature|entity <name> [--root <path>] [--dry-run]
              swift package --allow-writing-to-package-directory fsd-generate module <Name> --output <path> [--dry-run]

            Examples:
              swift package --allow-writing-to-package-directory fsd-generate slice feature export-report --root Sources/App
              swift package --allow-writing-to-package-directory fsd-generate module Reporting --output ../ReportingModule

            The plugin delegates to the fsd-ios CLI target, so generated output,
            validation, dry-run behavior, and overwrite protection stay identical
            to `fsd-ios create`.
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
