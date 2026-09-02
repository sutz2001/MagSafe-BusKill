//
//  CryptomatorMountParser.swift
//  MagSafe Guard
//

import Foundation

/// Detects Cryptomator mount points from `/sbin/mount` output (BusKill trigger_cryptomator_umount style).
enum CryptomatorMountParser {

  static func parseMountPoints(from mountOutput: String) -> [String] {
    var points: [String] = []
    for line in mountOutput.split(separator: "\n") {
      let text = String(line)
      let lower = text.lowercased()
      guard lower.contains("cryptomator") || lower.contains(":42427/") else { continue }
      guard let mountPoint = extractVolumeMountPoint(from: text) else { continue }
      if !points.contains(mountPoint) {
        points.append(mountPoint)
      }
    }
    return points
  }

  static func extractVolumeMountPoint(from line: String) -> String? {
    guard let onRange = line.range(of: " on ") else { return nil }
    let afterOn = line[onRange.upperBound...]
    guard let parenRange = afterOn.range(of: " (") else { return nil }
    let path = String(afterOn[..<parenRange.lowerBound])
    guard path.hasPrefix("/Volumes/") else { return nil }
    return path
  }
}
