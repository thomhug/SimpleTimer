import SwiftUI

struct SettingsView: View {
    var sections: [TimerSection]
    @AppStorage("appearance") private var appearance: String = "system"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                ForEach(sections) { section in
                    Section("Timer \(section.id + 1)") {
                        TimerConfigRow(section: section)

                        Picker("Ton", selection: Bindable(section).selectedSound) {
                            ForEach(SoundOption.allCases) { sound in
                                Text(sound.rawValue).tag(sound)
                            }
                        }
                        .onChange(of: section.selectedSound) {
                            section.selectedSound.play()
                        }

                        if !section.isStopwatch {
                            Toggle("Endlosschleife", isOn: Bindable(section).loopEnabled)
                        }
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

    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if section.configuredSeconds == 0 {
                Text("Stoppuhr")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Picker("Minuten", selection: $selectedMinutes) {
                    ForEach(0..<60) { m in
                        Text("\(m) Min").tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .clipped()

                Picker("Sekunden", selection: $selectedSeconds) {
                    ForEach(0..<60) { s in
                        Text("\(s) Sek").tag(s)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .clipped()
            }
            .labelsHidden()
        }
        .onAppear {
            selectedMinutes = section.configuredSeconds / 60
            selectedSeconds = section.configuredSeconds % 60
        }
        .onChange(of: selectedMinutes) { updateConfigured() }
        .onChange(of: selectedSeconds) { updateConfigured() }
    }

    private func updateConfigured() {
        let total = selectedMinutes * 60 + selectedSeconds
        if total != section.configuredSeconds {
            section.configuredSeconds = total
        }
    }
}
