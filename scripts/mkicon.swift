import AppKit
import CoreGraphics

// 生成应用图标：深色圆角底板 + 刘海符号
// 用法: swift mkicon.swift <输出 png 路径> [尺寸，默认 1024]

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
let size = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2]) ?? 1024 : 1024

let S = CGFloat(size)
let inset = S * 0.0977                       // 苹果图标的四周留白（1024 下约 100）
let side = S - inset * 2
let radius = side * 0.2237

guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                 isPlanar: false, colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 0) else { exit(1) }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
let cs = CGColorSpaceCreateDeviceRGB()

// 底板
let board = NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: side, height: side),
                         xRadius: radius, yRadius: radius)
board.addClip()

let topColor = CGColor(red: 0.157, green: 0.176, blue: 0.204, alpha: 1)     // #282D34
let botColor = CGColor(red: 0.031, green: 0.035, blue: 0.043, alpha: 1)     // #08090B
if let g = CGGradient(colorsSpace: cs, colors: [topColor, botColor] as CFArray, locations: [0, 1]) {
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])
}
if let g = CGGradient(colorsSpace: cs,
                      colors: [CGColor(red: 0.38, green: 0.56, blue: 0.80, alpha: 0.26),
                               CGColor(red: 0.38, green: 0.56, blue: 0.80, alpha: 0)] as CFArray,
                      locations: [0, 1]) {
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: S / 2, y: S), startRadius: 0,
                           endCenter: CGPoint(x: S / 2, y: S), endRadius: S * 0.85, options: [])
}

// 屏幕轮廓 + 顶部中央的刘海缺口
let scrW = side * 0.70
let scrH = side * 0.44
let scrR = side * 0.055
let scrX = (S - scrW) / 2
let scrY = (S - scrH) / 2

NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: scrX, y: scrY, width: scrW, height: scrH),
             xRadius: scrR, yRadius: scrR).fill()

// 刘海：从屏幕上沿中央垂下的深色块，下沿两角圆
let tabW = side * 0.162
let tabH = side * 0.094
let tr = min(tabW / 2, tabH * 0.34)
let cx = S / 2
let topEdge = scrY + scrH

let tab = NSBezierPath()
tab.move(to: NSPoint(x: cx - tabW / 2, y: topEdge + 6))
tab.line(to: NSPoint(x: cx - tabW / 2, y: topEdge - tabH + tr))
tab.appendArc(withCenter: NSPoint(x: cx - tabW / 2 + tr, y: topEdge - tabH + tr),
              radius: tr, startAngle: 180, endAngle: 270, clockwise: false)
tab.line(to: NSPoint(x: cx + tabW / 2 - tr, y: topEdge - tabH))
tab.appendArc(withCenter: NSPoint(x: cx + tabW / 2 - tr, y: topEdge - tabH + tr),
              radius: tr, startAngle: 270, endAngle: 360, clockwise: false)
tab.line(to: NSPoint(x: cx + tabW / 2, y: topEdge + 6))
tab.close()
NSColor(calibratedRed: 0.043, green: 0.047, blue: 0.055, alpha: 1).setFill()
tab.fill()

// 底板内描边
NSColor.white.withAlphaComponent(0.09).setStroke()
let edge = NSBezierPath(roundedRect: NSRect(x: inset + 0.5, y: inset + 0.5, width: side - 1, height: side - 1),
                        xRadius: radius, yRadius: radius)
edge.lineWidth = 1
edge.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try! png.write(to: URL(fileURLWithPath: outPath))
print("已写出 \(outPath)  \(size)x\(size)")
