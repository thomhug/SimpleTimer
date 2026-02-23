import Foundation

struct TimerLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let seconds: Int

    init(timestamp: Date, seconds: Int) {
        self.id = UUID()
        self.timestamp = timestamp
        self.seconds = seconds
    }
}

@Observable
final class TimerLog {
    static let shared = TimerLog()
    private(set) var entries: [TimerLogEntry] = []

    var totalSeconds: Int { entries.reduce(0) { $0 + $1.seconds } }

    private static let storageKey = "timerLogEntries"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([TimerLogEntry].self, from: data) {
            entries = saved
        }
    }

    func log(seconds: Int) {
        entries.insert(TimerLogEntry(timestamp: Date(), seconds: seconds), at: 0)
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
