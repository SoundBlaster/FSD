/// Tiny marker target that makes the root tooling package visible in Xcode.
///
/// The actual generator implementation lives in `tools/fsd-ios.swift` and is
/// exposed to Xcode/SwiftPM through `FSDGeneratorPlugin`.
public enum FSDToolingSupport {
    public static let packageName = "FSDTools"
    public static let generatorPluginVerb = "fsd-generate"
}
