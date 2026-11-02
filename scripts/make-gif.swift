import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// usage: swift make-gif.swift <out.gif> <width> <frame.png:delaySeconds> ...
// Builds an animated GIF from PNG frames, scaled to <width> with the aspect of
// the first frame. Delay is per frame, in seconds.

let args = CommandLine.arguments
guard args.count >= 4, let width = Int(args[2]) else {
    print("usage: make-gif.swift <out.gif> <width> <frame.png:delay>...")
    exit(2)
}

struct Frame {
    let image: CGImage
    let delay: Double
}

func load(_ path: String) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else {
        return nil
    }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func scaled(_ image: CGImage, width: Int) -> CGImage? {
    let height = max(1, Int((Double(image.height) * Double(width) / Double(image.width)).rounded()))
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: space,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        return nil
    }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return context.makeImage()
}

var frames: [Frame] = []
for spec in args[3...] {
    let parts = spec.split(separator: ":", maxSplits: 1)
    guard let image = load(String(parts[0])) else {
        print("cannot read \(parts[0])")
        exit(1)
    }
    guard let resized = scaled(image, width: width) else { exit(1) }
    let delay = parts.count > 1 ? (Double(parts[1]) ?? 1.0) : 1.0
    frames.append(Frame(image: resized, delay: delay))
}

let out = URL(fileURLWithPath: args[1])
guard let destination = CGImageDestinationCreateWithURL(out as CFURL,
                                                        UTType.gif.identifier as CFString,
                                                        frames.count, nil) else {
    print("cannot create \(out.path)")
    exit(1)
}

CGImageDestinationSetProperties(destination, [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
] as CFDictionary)

for frame in frames {
    CGImageDestinationAddImage(destination, frame.image, [
        kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: frame.delay]
    ] as CFDictionary)
}

guard CGImageDestinationFinalize(destination) else { exit(1) }
print("wrote \(out.path)")
