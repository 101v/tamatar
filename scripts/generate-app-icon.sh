#!/usr/bin/env bash
# Regenerates Packaging/AppIcon.icns from the same 🍅 glyph used in the menu bar.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

cat > "${WORKDIR}/GenerateIcon.swift" << 'EOF'
import AppKit
import Foundation

let outDir = CommandLine.arguments[1]
let iconset = (outDir as NSString).appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

let entries: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("diana.w@example.org", 32),
    ("icon_32x32.png", 32),
    ("ivan.p@example.net", 64),
    ("icon_128x128.png", 128),
    ("wendy.h@example.net", 256),
    ("icon_256x256.png", 256),
    ("lyanna.c@example.com", 512),
    ("icon_512x512.png", 512),
    ("walt.e@example.net", 1024),
]

func renderTomato(size: CGFloat) -> NSBitmapImageRep {
    let pixels = Int(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.cgContext.setShouldAntialias(true)
    ctx.cgContext.interpolationQuality = .high

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let font = NSFont.systemFont(ofSize: size * 0.92)
    let text = NSAttributedString(string: "🍅", attributes: [.font: font])
    let rect = text.boundingRect(
        with: NSSize(width: size * 2, height: size * 2),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
    text.draw(at: NSPoint(
        x: (size - rect.width) / 2,
        y: (size - rect.height) / 2 - size * 0.02
    ))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

for (name, size) in entries {
    let rep = renderTomato(size: size)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fputs("Failed to encode \(name)\n", stderr)
        exit(1)
    }
    try data.write(to: URL(fileURLWithPath: (iconset as NSString).appendingPathComponent(name)))
}
EOF

swift "${WORKDIR}/GenerateIcon.swift" "${WORKDIR}"
iconutil -c icns "${WORKDIR}/AppIcon.iconset" -o "${ROOT}/Packaging/AppIcon.icns"
echo "Wrote ${ROOT}/Packaging/AppIcon.icns"
