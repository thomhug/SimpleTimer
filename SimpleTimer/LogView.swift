import SwiftUI

struct LogView: View {
    @Environment(\.dismiss) private var dismiss
    private var log = TimerLog.shared

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if log.entries.isEmpty {
                    ContentUnavailableView(
                        "Kein Protokoll",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Timer-Ereignisse erscheinen hier.")
                    )
                } else {
                    List(log.entries) { entry in
                        HStack {
                            Text(Self.timeFormatter.string(from: entry.timestamp))
                                .font(.body.monospaced())
                                .foregroundStyle(.secondary)
                            Text("Timer \(entry.timerID + 1)")
                                .fontWeight(.medium)
                            Spacer()
                            Text(entry.event.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Protokoll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !log.entries.isEmpty {
                        Button("Löschen", role: .destructive) {
                            log.clear()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}
