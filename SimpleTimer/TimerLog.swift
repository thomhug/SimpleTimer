import Foundation

struct TimerLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let seconds: Int
    let timerName: String

    init(timestamp: Date, seconds: Int, timerName: String = "Timer") {
        self.id = UUID()
        self.timestamp = timestamp
        self.seconds = seconds
        self.timerName = timerName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        seconds = try container.decode(Int.self, forKey: .seconds)
        timerName = try container.decodeIfPresent(String.self, forKey: .timerName) ?? "Timer"
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

    func log(seconds: Int, timerName: String = "Timer") {
        entries.insert(TimerLogEntry(timestamp: Date(), seconds: seconds, timerName: timerName), at: 0)
        save()
    }

    func delete(id: UUID) {
        entries.removeAll { $0.id == id }
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
