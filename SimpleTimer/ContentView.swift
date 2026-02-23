import SwiftUI

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

    var body: some View {
        HStack {
            Spacer()

            ZStack(alignment: .topTrailing) {
                Text(section.displayTime)
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .foregroundStyle(section.isRunning ? .primary : .secondary)
                    .contentTransition(.numericText())
                    .onTapGesture {
                        withAnimation {
                            section.toggle()
                        }
                    }

                if section.loopEnabled && !section.isStopwatch {
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .offset(x: 4, y: -2)
                }
            }

            Spacer()

            Button {
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
    }
}
