import SwiftUI

struct ContentView: View {
    @State private var sections = [
        TimerSection(id: 0),
        TimerSection(id: 1),
        TimerSection(id: 2)
    ]
    @State private var showSettings = false

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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(sections: sections)
            }
        }
    }
}

struct TimerRow: View {
    @Bindable var section: TimerSection

    var body: some View {
        HStack {
            Spacer()

            Text(section.displayTime)
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .foregroundStyle(section.isRunning ? .primary : .secondary)
                .contentTransition(.numericText())
                .onTapGesture {
                    withAnimation {
                        section.toggle()
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
