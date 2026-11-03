import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// usage: swift clean-capture.swift <in.png> <out.png> [--notch W,H,R] [--bar N] [--glint]
//
// Prepares a screencapture for the README animation. Two jobs:
//
//   1. Remove everything the system draws inside the menu bar strip — the
//      application menus on the left and the status items on the right — so the
//      clip only shows the strip itself.
//   2. Draw a notch. macOS screencapture never includes the camera housing, so a
//      frame of a real screen would otherwise look like a plain black bar.
//
// When the strip is black (overlay on) the removal is a threshold: anything
// brighter than the strip is text or an icon, so it can simply go black. When the
// overlay is off the strip is wallpaper, and the columns behind the menus are
// refilled with the colour of the nearest column that has no text.
//
// The notch is drawn as a plain black shape with no outline. With the strip on it
// therefore vanishes into the black, which is the whole point of the app; only
// the frame with the strip off shows it. Pass --glint to add a faint edge along
// its sides instead.

struct Bitmap {
    var width: Int
    var height: Int
    var pixels: [UInt8]
}

func load(_ path: String) -> Bitmap {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        print("cannot read \(path)")
        exit(1)
    }
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let space = CGColorSpaceCreateDeviceRGB()
    pixels.withUnsafeMutableBytes { raw in
        let context = CGContext(data: raw.baseAddress, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    return Bitmap(width: width, height: height, pixels: pixels)
}

func save(_ bitmap: Bitmap, to path: String) {
    let space = CGColorSpaceCreateDeviceRGB()
    let data = Data(bitmap.pixels)
    guard let provider = CGDataProvider(data: data as CFData),
          let image = CGImage(width: bitmap.width, height: bitmap.height,
                              bitsPerComponent: 8, bitsPerPixel: 32,
                              bytesPerRow: bitmap.width * 4, space: space,
                              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                              provider: provider, decode: nil, shouldInterpolate: false,
                              intent: .defaultIntent) else {
        print("cannot build image")
        exit(1)
    }
    guard let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
                                                            UTType.png.identifier as CFString, 1, nil) else {
        print("cannot write \(path)")
        exit(1)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { exit(1) }
}

// MARK: - arguments

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: clean-capture.swift <in.png> <out.png> [--notch W,H,R] [--bar N]")
    exit(2)
}
let inputPath = args[1]
let outputPath = args[2]

var notch: (width: Int, height: Int, radius: Int)? = nil
var forcedBar: Int? = nil
var glintEnabled = false
var index = 3
while index < args.count {
    switch args[index] {
    case "--notch":
        let parts = args[index + 1].split(separator: ",").compactMap { Int($0) }
        if parts.count == 3 { notch = (parts[0], parts[1], parts[2]) }
        index += 2
    case "--glint":
        glintEnabled = true
        index += 1
    case "--bar":
        forcedBar = Int(args[index + 1])
        index += 2
    default:
        index += 1
    }
}

var bitmap = load(inputPath)
let width = bitmap.width
let height = bitmap.height

func luminance(_ x: Int, _ y: Int) -> Int {
    let i = (y * width + x) * 4
    return (Int(bitmap.pixels[i]) * 299 + Int(bitmap.pixels[i + 1]) * 587 + Int(bitmap.pixels[i + 2]) * 114) / 1000
}

// MARK: - strip height

/// Height of the black strip, measured on columns that carry no text: the run of
/// near-black pixels starting at the top edge gives the overlay height directly.
func blackRun(at x: Int) -> Int {
    var run = 0
    while run < height && luminance(x, run) < 28 { run += 1 }
    return run
}

let probeColumns = [width / 4, width / 2, width * 3 / 4].filter { $0 < width }
let runs = probeColumns.map { blackRun(at: $0) }.sorted()
let detected = runs[runs.count / 2]
let isBlackStrip = detected > 12
let bar = forcedBar ?? (isBlackStrip ? detected : 80)

print("size \(width)x\(height) strip=\(bar) black=\(isBlackStrip)")

// MARK: - remove menu bar contents

if isBlackStrip {
    // Text and icons are the only bright things inside a black strip.
    var cleared = 0
    for y in 0 ..< min(bar, height) {
        for x in 0 ..< width {
            let i = (y * width + x) * 4
            let lum = (Int(bitmap.pixels[i]) * 299 + Int(bitmap.pixels[i + 1]) * 587 + Int(bitmap.pixels[i + 2]) * 114) / 1000
            if lum > 40 {
                bitmap.pixels[i] = 0
                bitmap.pixels[i + 1] = 0
                bitmap.pixels[i + 2] = 0
                cleared += 1
            }
        }
    }
    print("cleared \(cleared) px inside the black strip")
} else {
    // A column is "clean" when its colour barely varies down the strip; text and
    // icons make it jump around.
    var deviation = [Double](repeating: 0, count: width)
    let rows = min(bar, height)
    for x in 0 ..< width {
        var values = [Double]()
        values.reserveCapacity(rows)
        for y in 0 ..< rows { values.append(Double(luminance(x, y))) }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        deviation[x] = variance.squareRoot()
    }

    let cleanThreshold = 3.0
    var bestStart = 0, bestLength = 0
    var runStart: Int? = nil
    for x in 0 ... width {
        let clean = x < width && deviation[x] < cleanThreshold
        if clean, runStart == nil { runStart = x }
        if !clean, let start = runStart {
            if x - start > bestLength { bestLength = x - start; bestStart = start }
            runStart = nil
        }
    }
    guard bestLength > width / 4 else {
        print("no clean stretch found in the strip, aborting")
        exit(1)
    }
    let cleanLeft = bestStart
    let cleanRight = bestStart + bestLength - 1
    print("clean columns \(cleanLeft)..\(cleanRight)")

    func refill(_ x: Int, from source: Int) {
        let s = (rows / 2 * width + source) * 4
        for y in 0 ..< rows {
            let i = (y * width + x) * 4
            bitmap.pixels[i] = bitmap.pixels[s]
            bitmap.pixels[i + 1] = bitmap.pixels[s + 1]
            bitmap.pixels[i + 2] = bitmap.pixels[s + 2]
        }
    }
    for x in 0 ..< cleanLeft { refill(x, from: cleanLeft) }
    for x in (cleanRight + 1) ..< width { refill(x, from: cleanRight) }
    print("refilled \(cleanLeft + (width - cleanRight - 1)) columns")
}

// MARK: - draw the notch

if let notch, notch.width > 0 {
    let x0 = Double(width - notch.width) / 2
    let x1 = x0 + Double(notch.width)
    let bottom = Double(min(notch.height, height))
    let radius = Double(min(notch.radius, notch.height / 2))
    let samples = 4

    /// Coverage of the notch shape for one pixel, 4x4 supersampled so the rounded
    /// bottom corners stay smooth.
    func coverage(_ px: Int, _ py: Int) -> Double {
        var hits = 0
        for sy in 0 ..< samples {
            for sx in 0 ..< samples {
                let x = Double(px) + (Double(sx) + 0.5) / Double(samples)
                let y = Double(py) + (Double(sy) + 0.5) / Double(samples)
                guard x >= x0, x <= x1, y <= bottom else { continue }
                if y >= bottom - radius {
                    let dy = y - (bottom - radius)
                    if x < x0 + radius {
                        if (x - (x0 + radius)) * (x - (x0 + radius)) + dy * dy > radius * radius { continue }
                    } else if x > x1 - radius {
                        if (x - (x1 - radius)) * (x - (x1 - radius)) + dy * dy > radius * radius { continue }
                    }
                }
                hits += 1
            }
        }
        return Double(hits) / Double(samples * samples)
    }

    // Distance from a point inside the shape to its closest edge. Used to draw
    // the glint along the two vertical sides.
    func inset(_ x: Double, _ y: Double) -> Double {
        let cornerY = bottom - radius
        if y < cornerY { return min(x - x0, x1 - x) }
        let left = x0 + radius, right = x1 - radius
        if x < left { return radius - ((x - left) * (x - left) + (y - cornerY) * (y - cornerY)).squareRoot() }
        if x > right { return radius - ((x - right) * (x - right) + (y - cornerY) * (y - cornerY)).squareRoot() }
        return bottom - y
    }

    // The notch is a hole in the panel, so it is the same black as the strip and
    // disappears into it — exactly what the app is for. A glint along the sides
    // is therefore off by default; only the frame where the strip is off shows
    // the notch as a black shape against the wallpaper.
    let glintWidth = 5.0
    let glintAlpha: Double = glintEnabled ? 0.45 : 0.0
    var inside = 0, glints = 0
    for y in 0 ..< Int(bottom.rounded(.up)) {
        for x in Int(x0.rounded(.down)) ... min(width - 1, Int(x1.rounded(.up))) {
            guard x >= 0 else { continue }
            let cover = coverage(x, y)
            guard cover > 0 else { continue }
            let i = (y * width + x) * 4
            for channel in 0 ..< 3 {
                let base = Double(bitmap.pixels[i + channel])
                bitmap.pixels[i + channel] = UInt8(max(0, min(255, base * (1 - cover))))
            }
            // Sides only: the bottom edge already meets the strip's own edge, so a
            // line there would just read as a seam.
            let depth = inset(Double(x) + 0.5, Double(y) + 0.5)
            let onBottomEdge = Double(y) > bottom - radius
                && Double(x) > x0 + radius && Double(x) < x1 - radius
            let onSide = depth < glintWidth && !onBottomEdge
            if onSide {
                let weight = cover * glintAlpha * (1 - depth / glintWidth)
                for channel in 0 ..< 3 {
                    let base = Double(bitmap.pixels[i + channel])
                    bitmap.pixels[i + channel] = UInt8(max(0, min(255, base + (255 - base) * weight)))
                }
                glints += 1
            }
            if cover > 0.5 { inside += 1 }
        }
    }
    print("notch \(notch.width)x\(notch.height) r=\(notch.radius) inside=\(inside)"
          + (glintEnabled ? " glints=\(glints)" : ""))
}

save(bitmap, to: outputPath)
print("wrote \(outputPath)")
