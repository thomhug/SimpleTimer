import SwiftUI
import UIKit

struct ContentView: View {
    @State private var sections = [
        TimerSection(id: 0),
        TimerSection(id: 1),
        TimerSection(id: 2)
    ]
    @State private var showSettings = false
    @State private var showLog = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                    if index > 0 {
                        Divider()
                    }
                    TimerRow(section: section)
                        .frame(maxHeight: .infinity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showLog = true
                    } label: {
                        Image(systemName: "list.bullet.clipboard")
                    }
                    .accessibilityIdentifier("log-button")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityIdentifier("settings-button")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(sections: sections)
            }
            .sheet(isPresented: $showLog) {
                LogView()
            }
        }
    }
}

struct TimerRow: View {
    @Bindable var section: TimerSection
    @State private var showQuickConfig = false

    private var progress: CGFloat {
        guard !section.isStopwatch, section.configuredSeconds > 0 else { return 0 }
        return CGFloat(section.remainingSeconds) / CGFloat(section.configuredSeconds)
    }

    var body: some View {
        HStack {
            Spacer()

            VStack(spacing: 6) {
                Text(section.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topTrailing) {
                    Text(section.displayTime)
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .foregroundStyle(section.isRunning ? .primary : .secondary)
                        .contentTransition(.numericText())

                    if section.loopEnabled && !section.isStopwatch {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .offset(x: 4, y: -2)
                    }
                }

                if !section.isStopwatch {
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.15), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: progress)
                    }
                    .frame(width: 32, height: 32)
                }
            }
            .onTapGesture {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                withAnimation {
                    section.toggle()
                }
            }
            .onLongPressGesture {
                showQuickConfig = true
            }

            Spacer()

            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                withAnimation {
                    section.reset()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .padding(.trailing, 20)
        }
        .sheet(isPresented: $showQuickConfig) {
            QuickConfigSheet(section: section)
                .presentationDetents([.medium])
        }
    }
}

struct QuickConfigSheet: View {
    @Bindable var section: TimerSection
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
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
                }

                Section {
                    Picker("Sound", selection: $section.selectedSound) {
                        ForEach(SoundOption.allCases) { sound in
                            Text(sound.rawValue).tag(sound)
                        }
                    }

                    if !section.isStopwatch {
                        Toggle("Loop", isOn: $section.loopEnabled)
                    }
                }
            }
            .navigationTitle(section.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                selectedMinutes = section.configuredSeconds / 60
                selectedSeconds = section.configuredSeconds % 60
            }
            .onChange(of: selectedMinutes) { updateConfigured() }
            .onChange(of: selectedSeconds) { updateConfigured() }
        }
    }

    private func updateConfigured() {
        let total = selectedMinutes * 60 + selectedSeconds
        if total != section.configuredSeconds {
            section.configuredSeconds = total
        }
    }
}
