import Foundation

enum TimerEvent: String {
    case started = "Gestartet"
    case stopped = "Gestoppt"
    case reset = "Zurückgesetzt"
    case finished = "Abgelaufen"
}

struct TimerLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let timerID: Int
    let event: TimerEvent
}

@Observable
final class TimerLog {
    static let shared = TimerLog()
    private(set) var entries: [TimerLogEntry] = []

    private init() {}

    func log(_ event: TimerEvent, timerID: Int) {
        let entry = TimerLogEntry(timestamp: Date(), timerID: timerID, event: event)
        entries.insert(entry, at: 0)
    }

    func clear() {
        entries.removeAll()
    }
}
