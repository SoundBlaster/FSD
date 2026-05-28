class FsdIos < Formula
  desc "Feature-Sliced Design toolkit for SwiftUI and SwiftData iOS projects"
  homepage "https://github.com/SoundBlaster/FSD"
  url "https://github.com/SoundBlaster/FSD/releases/download/v0.4.0/fsd-ios-0.4.0.tar.gz"
  sha256 "c1cccb45bbf2cad5d336a639a4c63996aa79b2d33b67f3a7a5eb3b124b692823"
  license "MIT"

  def install
    libexec.install "libexec/fsd-ios"

    (bin/"fsd-ios").write <<~SH
      #!/bin/sh
      set -eu
      exec "${SWIFT:-swift}" "#{libexec}/fsd-ios/tools/fsd-ios.swift" "$@"
    SH
  end

  def caveats
    "fsd-ios runs Swift scripts, so `swift` must be available on PATH."
  end

  test do
    assert_match "fsd-ios 0.4.0", shell_output("#{bin}/fsd-ios --version")
    doctor = shell_output("#{bin}/fsd-ios doctor --json")
    assert_match "\"tool\" : \"fsd-ios\"", doctor
    assert_match "\"version\" : \"0.4.0\"", doctor
    assert_match "\"passed\" : true", doctor
  end
end
