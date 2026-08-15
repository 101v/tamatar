class Tamatar < Formula
  desc "macOS menu-bar Pomodoro timer"
  homepage "https://github.com/101v/tamatar"
  license "MIT"
  head "https://github.com/101v/tamatar.git", branch: "main"

  # After tagging v1.0.0, uncomment and set the checksum (see RELEASING.md):
  # url "https://github.com/101v/tamatar/archive/refs/tags/v1.0.0.tar.gz"
  # sha256 "REPLACE_WITH_TARBALL_SHA256"

  depends_on xcode: ["15.0", :build]
  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/Tamatar"
  end

  def caveats
    <<~EOS
      Tamatar runs as a menu-bar app (no Dock icon). Start it with:

        Tamatar

      Quit from the 🍅 menu, or with:

        killall Tamatar
    EOS
  end

  test do
    assert_predicate bin/"Tamatar", :executable?
  end
end
