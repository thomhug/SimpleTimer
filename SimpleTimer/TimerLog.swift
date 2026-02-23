import Foundation

struct TimerLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let seconds: Int
}

@Observable
final class TimerLog {
    static let shared = TimerLog()
    private(set) var entries: [TimerLogEntry] = []

    var totalSeconds: Int { entries.reduce(0) { $0 + $1.seconds } }

    private init() {}

    func log(seconds: Int) {
        entries.insert(TimerLogEntry(timestamp: Date(), seconds: seconds), at: 0)
    }

    func clear() {
        entries.removeAll()
    }
}
