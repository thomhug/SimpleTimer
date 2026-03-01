import SwiftUI

struct SettingsView: View {
    var sections: [TimerSection]
    @AppStorage("appearance") private var appearance: String = "system"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                ForEach(sections) { section in
                    TimerSettingsSection(section: section)
                }

                Section("Appearance") {
                    Picker("Background", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Text("Version \(Bundle.main.appVersionString)")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

struct TimerSettingsSection: View {
    @Bindable var section: TimerSection

    var body: some View {
        Section(section.name) {
            TextField("Name", text: $section.name)

            TimerConfigRow(section: section)

            HStack {
                Picker("Sound", selection: $section.selectedSound) {
                    ForEach(SoundOption.allCases) { sound in
                        Text(sound.rawValue).tag(sound)
                    }
                }

                Button {
                    section.selectedSound.play()
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.borderless)
            }

            if !section.isStopwatch {
                Toggle("Loop", isOn: $section.loopEnabled)
            }
        }
    }
}

struct TimerConfigRow: View {
    @Bindable var section: TimerSection

    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0

    private let presets: [(String, Int)] = [
        ("1", 60),
        ("5", 300),
        ("10", 600),
        ("15", 900),
        ("30", 1800)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if section.configuredSeconds == 0 {
                Text("Stopwatch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(0..<60) { m in
                        Text("\(m) min").tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .clipped()

                Picker("Seconds", selection: $selectedSeconds) {
                    ForEach(0..<60) { s in
                        Text("\(s) sec").tag(s)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .clipped()
            }
            .labelsHidden()

            HStack(spacing: 8) {
                ForEach(presets, id: \.1) { label, totalSeconds in
                    Button {
                        selectedMinutes = totalSeconds / 60
                        selectedSeconds = totalSeconds % 60
                    } label: {
                        Text("\(label) min")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                section.configuredSeconds == totalSeconds
                                    ? Color.accentColor
                                    : Color(.systemGray5)
                            )
                            .foregroundStyle(
                                section.configuredSeconds == totalSeconds
                                    ? .white
                                    : .primary
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
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
