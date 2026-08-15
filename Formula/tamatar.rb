class Tamatar < Formula
  desc "macOS menu-bar Pomodoro timer"
  homepage "https://github.com/101v/tamatar"
  url "https://github.com/101v/tamatar/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "37886d7f7726036646d64e9b8abfb818a873a0f345037a8de2ac17c84d79a2bc"
  license "MIT"
  head "https://github.com/101v/tamatar.git", branch: "main"

  depends_on xcode: ["15.0", :build]
  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"

    contents = prefix/"Tamatar.app/Contents"
    (contents/"MacOS").mkpath
    (contents/"Resources").mkpath
    (contents/"MacOS").install ".build/release/Tamatar"
    contents.install "Packaging/Info.plist"
    (contents/"Resources").install "Packaging/AppIcon.icns"

    # Launch via Launch Services so the terminal is not blocked and Spotlight can find the .app.
    # One name only: macOS default volumes are case-insensitive, so Tamatar/tamatar collide in bin/.
    (bin/"tamatar").write <<~EOS
      #!/bin/bash
      exec open "#{opt_prefix}/Tamatar.app" --args "$@"
    EOS
    chmod "+x", bin/"tamatar"
  end

  def post_install
    apps = Pathname.new(Dir.home)/"Applications"
    apps.mkpath
    ln_sf opt_prefix/"Tamatar.app", apps/"Tamatar.app"
  end

  def caveats
    <<~EOS
      Tamatar is a menu-bar app (no Dock icon). Start it with:

        tamatar

      or via Spotlight after it indexes ~/Applications/Tamatar.app.

      Quit from the 🍅 menu, or with:

        killall Tamatar
    EOS
  end

  test do
    assert_predicate prefix/"Tamatar.app/Contents/MacOS/Tamatar", :executable?
    assert_predicate prefix/"Tamatar.app/Contents/Resources/AppIcon.icns", :exist?
    assert_predicate bin/"tamatar", :executable?
  end
end
