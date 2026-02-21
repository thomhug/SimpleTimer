import SwiftUI

struct SettingsView: View {
    var sections: [TimerSection]
    @AppStorage("appearance") private var appearance: String = "system"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Timer") {
                    ForEach(sections) { section in
                        TimerConfigRow(section: section)
                    }
                }

                Section("Darstellung") {
                    Picker("Hintergrund", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Hell").tag("light")
                        Text("Dunkel").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimerConfigRow: View {
    @Bindable var section: TimerSection

    @State private var minuteText: String = ""
    @State private var secondText: String = ""

    var body: some View {
        HStack {
            Text("Timer \(section.id + 1)")
            Spacer()
            HStack(spacing: 2) {
                TextField("0", text: $minuteText)
                    .keyboardType(.numberPad)
                    .frame(width: 30)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: minuteText) { updateSeconds() }
                Text(":")
                TextField("00", text: $secondText)
                    .keyboardType(.numberPad)
                    .frame(width: 30)
                    .onChange(of: secondText) { updateSeconds() }
            }
            .font(.body.monospaced())

            Text(section.configuredSeconds == 0 ? "Stoppuhr" : "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
        }
        .onAppear {
            let m = section.configuredSeconds / 60
            let s = section.configuredSeconds % 60
            minuteText = "\(m)"
            secondText = String(format: "%02d", s)
        }
    }

    private func updateSeconds() {
        let m = Int(minuteText) ?? 0
        let s = min(59, Int(secondText) ?? 0)
        let total = m * 60 + s
        if total != section.configuredSeconds {
            section.configuredSeconds = total
        }
    }
}
