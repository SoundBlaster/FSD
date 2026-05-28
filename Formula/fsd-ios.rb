class FsdIos < Formula
  desc "Feature-Sliced Design toolkit for SwiftUI and SwiftData iOS projects"
  homepage "https://github.com/SoundBlaster/FSD"
  url "https://github.com/SoundBlaster/FSD/releases/download/v0.4.0/fsd-ios-0.4.0.tar.gz"
  sha256 "c1cccb45bbf2cad5d336a639a4c63996aa79b2d33b67f3a7a5eb3b124b692823"
  license "MIT"

  def install
    libexec.install "libexec/fsd-ios"

    wrapper = bin/"fsd-ios"
    wrapper.write <<~SH
      #!/bin/sh
      set -eu
      exec "${SWIFT:-swift}" "#{libexec}/fsd-ios/tools/fsd-ios.swift" "$@"
    SH
    chmod 0755, wrapper
  end

  def caveats
    "fsd-ios runs Swift scripts, so `swift` must be available on PATH."
  end

  test do
    ENV["HOME"] = testpath

    assert_match "fsd-ios 0.4.0", shell_output("#{bin}/fsd-ios --version")
    # Homebrew's test sandbox can make SwiftPM user caches unwritable.
    doctor = shell_output("#{bin}/fsd-ios doctor --json || true")
    assert_match "\"tool\" : \"fsd-ios\"", doctor
    assert_match "\"version\" : \"0.4.0\"", doctor
  end
end
