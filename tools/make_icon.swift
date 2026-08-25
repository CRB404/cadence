#!/usr/bin/env swift
// Renders the Cadence app icon: near-black rounded field with a countdown
// dial — a faint full ring, a bright progress arc sweeping from 12 o'clock,
// and a glowing knob at its tip (the app's capsule slider, as a dial).
// Sibling of Observatory's icon: same field, thin white geometry, one glow.
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError() }

// macOS icon grid: 824×824 rounded rect centered on a transparent 1024 canvas.
let margin: CGFloat = 100
let plate = CGRect(x: margin, y: margin, width: size - 2 * margin, height: size - 2 * margin)
let platePath = CGPath(roundedRect: plate, cornerWidth: 186, cornerHeight: 186, transform: nil)
ctx.addPath(platePath)
ctx.clip()

// Background: deep near-black with the faintest vertical lift (matches Observatory).
let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [NSColor(calibratedRed: 0.055, green: 0.06, blue: 0.07, alpha: 1).cgColor,
                             NSColor(calibratedRed: 0.027, green: 0.031, blue: 0.039, alpha: 1).cgColor] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

let center = CGPoint(x: size / 2, y: size / 2)
let radius: CGFloat = 250
let lineWidth: CGFloat = 42

// Faint full ring — the dial's track.
ctx.setStrokeColor(NSColor(calibratedWhite: 1, alpha: 0.14).cgColor)
ctx.setLineWidth(lineWidth)
ctx.setLineCap(.round)
ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
ctx.strokePath()

// Progress arc: from 12 o'clock, sweeping clockwise ~240° — time remaining.
let start: CGFloat = .pi / 2
let sweep: CGFloat = .pi * (240.0 / 180.0)
let end = start - sweep
ctx.setStrokeColor(NSColor(calibratedWhite: 1, alpha: 0.92).cgColor)
ctx.setLineWidth(lineWidth)
ctx.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
ctx.strokePath()

// The knob: a bright point at the arc's tip, soft glow — Observatory's star.
let knob = CGPoint(x: center.x + cos(end) * radius, y: center.y + sin(end) * radius)
let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                      colors: [NSColor(calibratedWhite: 1, alpha: 0.9).cgColor,
                               NSColor(calibratedWhite: 1, alpha: 0).cgColor] as CFArray,
                      locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: knob, startRadius: 0, endCenter: knob, endRadius: 110, options: [])
ctx.setFillColor(NSColor.white.cgColor)
ctx.fillEllipse(in: CGRect(x: knob.x - 34, y: knob.y - 34, width: 68, height: 68))

image.unlockFocus()

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else { fatalError() }
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
