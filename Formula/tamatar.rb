class Tamatar < Formula
  desc "macOS menu-bar Pomodoro timer"
  homepage "https://github.com/101v/tamatar"
  url "https://github.com/101v/tamatar/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "9aa4addb115d0531048259c0383fdc7556e9eff9da943593cc7ee4df14867272"
  license "MIT"
  head "https://github.com/101v/tamatar.git", branch: "main"

  depends_on xcode: ["15.0", :build]
  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"

    contents = prefix/"Tamatar.app/Contents"
    (contents/"MacOS").mkpath
    (contents/"MacOS").install ".build/release/Tamatar"
    contents.install "Packaging/Info.plist"

    # Launch via Launch Services so the terminal is not blocked and Spotlight can find the .app.
    (bin/"Tamatar").write <<~EOS
      #!/bin/bash
      exec open "#{opt_prefix}/Tamatar.app" --args "$@"
    EOS
    (bin/"tamatar").write <<~EOS
      #!/bin/bash
      exec open "#{opt_prefix}/Tamatar.app" --args "$@"
    EOS
    chmod "+x", bin/"Tamatar", bin/"tamatar"
  end

  def post_install
    apps = Pathname.new(Dir.home)/"Applications"
    apps.mkpath
    ln_sf opt_prefix/"Tamatar.app", apps/"Tamatar.app"
  end

  def caveats
    <<~EOS
      Tamatar is a menu-bar app (no Dock icon). Start it with:

        Tamatar

      or via Spotlight after it indexes ~/Applications/Tamatar.app.

      Quit from the 🍅 menu, or with:

        killall Tamatar
    EOS
  end

  test do
    assert_predicate prefix/"Tamatar.app/Contents/MacOS/Tamatar", :executable?
    assert_predicate bin/"Tamatar", :executable?
  end
end
