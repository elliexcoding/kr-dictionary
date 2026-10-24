#!/usr/bin/env swift
// Renders the app icon — a modern take on a traditional hanging scroll (족자)
// with a vermillion seal (낙관) — in the three variants iOS uses.
//
//     swift scripts/make_app_icon.swift [seal-character]
//
// Writes AppIcon.png, AppIcon-Dark.png and AppIcon-Tinted.png into
// KrDict/Assets.xcassets/AppIcon.appiconset/. Drawn in a 1024×1024 canvas with
// a top-left origin; iOS applies the rounded-corner mask itself.

import AppKit

let sealCharacter = CommandLine.arguments.dropFirst().first ?? "한"
let size: CGFloat = 1024
let outputDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("KrDict/Assets.xcassets/AppIcon.appiconset")

struct Palette {
    var backgroundTop: NSColor
    var backgroundBottom: NSColor
    var paperTop: NSColor
    var paperBottom: NSColor
    var paperEdge: NSColor
    var rod: NSColor
    var rodCap: NSColor
    var ink: NSColor
    var seal: NSColor
    var sealGlyph: NSColor
    var shadow: NSColor
}

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

func gray(_ white: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: white, green: white, blue: white, alpha: alpha)
}

let light = Palette(
    backgroundTop: rgb(0x2A3B63), backgroundBottom: rgb(0x141F38),
    paperTop: rgb(0xF7EFDF), paperBottom: rgb(0xEADBBE), paperEdge: rgb(0xD9C7A3),
    rod: rgb(0x7B4A2B), rodCap: rgb(0x4E2C17),
    ink: rgb(0x262A33), seal: rgb(0xC8372D), sealGlyph: rgb(0xFBF3E6),
    shadow: rgb(0x000000, 0.35)
)

let dark = Palette(
    backgroundTop: rgb(0x1A1F2B), backgroundBottom: rgb(0x07090E),
    paperTop: rgb(0xE6DCC8), paperBottom: rgb(0xD3C4A6), paperEdge: rgb(0xBFAE8C),
    rod: rgb(0x6A4026), rodCap: rgb(0x3F2312),
    ink: rgb(0x23262E), seal: rgb(0xB8322A), sealGlyph: rgb(0xF1E7D6),
    shadow: rgb(0x000000, 0.55)
)

// Tinted icons are supplied in grayscale; iOS applies the user's tint.
let tinted = Palette(
    backgroundTop: gray(0.0), backgroundBottom: gray(0.0),
    paperTop: gray(0.92), paperBottom: gray(0.82), paperEdge: gray(0.72),
    rod: gray(0.55), rodCap: gray(0.40),
    ink: gray(0.12), seal: gray(0.45), sealGlyph: gray(0.95),
    shadow: gray(0.0, 0)
)

// MARK: - Drawing helpers (top-left origin)

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x: x, y: size - y - h, width: w, height: h)
}

func fillGradient(_ path: NSBezierPath, top: NSColor, bottom: NSColor) {
    NSGradient(starting: bottom, ending: top)!.draw(in: path, angle: 90)
}

func roundedRect(_ r: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
}

func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: x, y: size - y)
}

/// A vertical brush stroke: a rounded press at the top that thins out and
/// tapers to a point, like ink running out at the end of a stroke.
func brushStroke(x: CGFloat, top: CGFloat, bottom: CGFloat, width: CGFloat) -> NSBezierPath {
    let half = width / 2
    let shoulder = top + half
    let path = NSBezierPath()
    path.move(to: point(x - half, shoulder))
    path.curve(to: point(x + half, shoulder),
               controlPoint1: point(x - half, top - half * 0.35),
               controlPoint2: point(x + half, top - half * 0.35))
    path.curve(to: point(x + 1.5, bottom),
               controlPoint1: point(x + half * 0.95, shoulder + (bottom - shoulder) * 0.55),
               controlPoint2: point(x + half * 0.45, bottom - (bottom - shoulder) * 0.12))
    path.curve(to: point(x - half * 0.55, shoulder + (bottom - shoulder) * 0.6),
               controlPoint1: point(x - 1.5, bottom),
               controlPoint2: point(x - half * 0.5, bottom - (bottom - shoulder) * 0.18))
    path.curve(to: point(x - half, shoulder),
               controlPoint1: point(x - half * 0.62, shoulder + (bottom - shoulder) * 0.3),
               controlPoint2: point(x - half, shoulder + half))
    path.close()
    return path
}

func drawIcon(_ p: Palette) {
    // Background
    fillGradient(NSBezierPath(rect: CGRect(x: 0, y: 0, width: size, height: size)),
                 top: p.backgroundTop, bottom: p.backgroundBottom)

    // Enlarge the scroll around the canvas center so it reads well at small
    // home-screen sizes; the layout below is authored at 1×.
    let zoom = NSAffineTransform()
    zoom.translateX(by: size / 2, yBy: size / 2)
    zoom.scale(by: 1.15)
    zoom.translateX(by: -size / 2, yBy: -size / 2)
    zoom.concat()

    // Scroll geometry
    let paper = rect(322, 214, 380, 596)
    let topRod = rect(270, 182, 484, 48)
    let bottomRod = rect(270, 794, 484, 48)

    // Soft drop shadow under the whole scroll
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = p.shadow
    shadow.shadowBlurRadius = 48
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    shadow.set()
    p.paperBottom.setFill()
    NSBezierPath(rect: paper).fill()
    roundedRect(topRod, radius: 24).fill()
    roundedRect(bottomRod, radius: 24).fill()
    NSGraphicsContext.restoreGraphicsState()

    // Paper, with a thin border mount like a traditional silk frame
    fillGradient(NSBezierPath(rect: paper), top: p.paperTop, bottom: p.paperBottom)
    p.paperEdge.setStroke()
    let mount = NSBezierPath(rect: paper.insetBy(dx: 22, dy: 22))
    mount.lineWidth = 4
    mount.stroke()

    // Rods with darker end caps
    for rod in [topRod, bottomRod] {
        p.rod.setFill()
        roundedRect(rod, radius: 24).fill()
        p.rodCap.setFill()
        roundedRect(CGRect(x: rod.minX, y: rod.minY, width: 44, height: rod.height), radius: 22).fill()
        roundedRect(CGRect(x: rod.maxX - 44, y: rod.minY, width: 44, height: rod.height), radius: 22).fill()
    }

    // Vertical ink strokes, read right to left like traditional writing
    p.ink.setFill()
    let strokes: [(x: CGFloat, top: CGFloat, bottom: CGFloat)] = [
        (612, 288, 712),
        (540, 288, 620),
        (468, 288, 548),
    ]
    for stroke in strokes {
        brushStroke(x: stroke.x, top: stroke.top, bottom: stroke.bottom, width: 36).fill()
    }

    // Seal stamp with a carved character
    let seal = rect(362, 620, 104, 104)
    p.seal.setFill()
    roundedRect(seal, radius: 14).fill()

    let font = NSFont(name: "AppleMyungjo", size: 76) ?? .boldSystemFont(ofSize: 76)
    let glyph = NSAttributedString(string: sealCharacter, attributes: [
        .font: font,
        .foregroundColor: p.sealGlyph,
    ])
    let glyphSize = glyph.size()
    glyph.draw(at: CGPoint(x: seal.midX - glyphSize.width / 2,
                           y: seal.midY - glyphSize.height / 2 + font.descender / 2))
}

// MARK: - Render

struct RenderError: Error {}

func render(_ palette: Palette, to filename: String) throws {
    // App Store icons must be opaque, so draw into a context with no alpha
    // channel at all (RGBX) rather than stripping it afterwards.
    guard let context = CGContext(
        data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { throw RenderError() }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    drawIcon(palette)
    NSGraphicsContext.restoreGraphicsState()

    let url = outputDirectory.appendingPathComponent(filename)
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { throw RenderError() }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw RenderError() }
    print("Wrote \(url.path)")
}

try render(light, to: "AppIcon.png")
try render(dark, to: "AppIcon-Dark.png")
try render(tinted, to: "AppIcon-Tinted.png")
