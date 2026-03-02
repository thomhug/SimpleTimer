#!/usr/bin/swift
// Generates realistic demo data for SimpleTimer screenshots.
// Writes JSON to stdout (pipe into seed-simulator.sh).
//
// Usage: swift scripts/generate-demo-data.swift > /tmp/demo_log_entries.json

import Foundation

struct TimerLogEntry: Codable {
    let id: UUID
    let timestamp: Date
    let seconds: Int
    let timerName: String
}

// Timer configs: name -> typical durations in seconds
let timerConfigs: [(name: String, durations: [Int], frequency: Double)] = [
    ("Meditation", [300, 600, 900, 1200], 0.85),    // 5-20 min, almost daily
    ("Workout",    [1800, 2700, 3600, 2400], 0.65),  // 30-60 min, ~5x/week
    ("Kochen",     [600, 900, 1200, 1500, 1800], 0.5) // 10-30 min, ~3-4x/week
]

let calendar = Calendar.current
let now = Date()
let today = calendar.startOfDay(for: now)
var entries: [TimerLogEntry] = []

// Generate entries for last 180 days (meaningful data for year view)
for daysAgo in 0..<180 {
    guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

    for config in timerConfigs {
        // Skip some days randomly based on frequency (but always include today for streak)
        if daysAgo > 0 && Double.random(in: 0...1) > config.frequency { continue }

        // Pick a plausible time of day per timer
        let hour: Int
        switch config.name {
        case "Meditation": hour = Int.random(in: 6...8)
        case "Workout":    hour = Int.random(in: 17...19)
        default:           hour = Int.random(in: 11...18)
        }
        let minute = Int.random(in: 0...59)

        guard let ts = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { continue }
        // Don't add future timestamps
        guard ts <= now else { continue }

        let duration = config.durations.randomElement()!
        entries.append(TimerLogEntry(id: UUID(), timestamp: ts, seconds: duration, timerName: config.name))
    }
}

// Sort newest first (matches app behavior)
entries.sort { $0.timestamp > $1.timestamp }

// Encode with DEFAULT strategy (.deferredToDate) — must match app's JSONDecoder()
let encoder = JSONEncoder()
// Do NOT set encoder.dateEncodingStrategy — default is .deferredToDate
let data = try! encoder.encode(entries)

// Write JSON to stdout
FileHandle.standardOutput.write(data)

// Summary to stderr
let summary = """

Generated \(entries.count) entries over 180 days
"""
FileHandle.standardError.write(summary.data(using: .utf8)!)
for config in timerConfigs {
    let count = entries.filter { $0.timerName == config.name }.count
    let totalMin = entries.filter { $0.timerName == config.name }.reduce(0) { $0 + $1.seconds } / 60
    let line = "  \(config.name): \(count) sessions, \(totalMin) min total\n"
    FileHandle.standardError.write(line.data(using: .utf8)!)
}
