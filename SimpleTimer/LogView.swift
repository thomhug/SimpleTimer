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
                    List {
                        Section {
                            ForEach(log.entries) { entry in
                                HStack {
                                    Text(Self.timeFormatter.string(from: entry.timestamp))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(Self.format(entry.seconds))
                                }
                                .font(.body.monospaced())
                            }
                        }

                        Section {
                            HStack {
                                Text("Gesamt")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(Self.format(log.totalSeconds))
                                    .fontWeight(.medium)
                            }
                            .font(.body.monospaced())
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

    private static func format(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
